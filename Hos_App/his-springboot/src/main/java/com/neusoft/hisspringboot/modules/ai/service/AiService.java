package com.neusoft.hisspringboot.modules.ai.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.neusoft.hisspringboot.common.BusinessException;
import com.neusoft.hisspringboot.common.ErrorCode;
import com.neusoft.hisspringboot.modules.ai.dto.AiMessageItem;
import com.neusoft.hisspringboot.modules.ai.dto.ChatMessage;
import com.neusoft.hisspringboot.modules.ai.dto.ChatResponse;
import com.neusoft.hisspringboot.modules.ai.dto.ConversationItem;
import com.neusoft.hisspringboot.modules.ai.entity.AiConversation;
import com.neusoft.hisspringboot.modules.ai.entity.AiMessage;
import com.neusoft.hisspringboot.modules.ai.mapper.AiConversationMapper;
import com.neusoft.hisspringboot.modules.ai.mapper.AiMessageMapper;
import com.neusoft.hisspringboot.modules.department.dto.DepartmentTreeNode;
import com.neusoft.hisspringboot.modules.department.service.DepartmentService;
import com.neusoft.hisspringboot.modules.schedule.dto.SlotSummary;
import com.neusoft.hisspringboot.modules.schedule.service.ScheduleSlotService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * AI 导诊：调用 DeepSeek（OpenAI 兼容）chat/completions，并支持 function calling 查询真实科室/号源。
 * 注册 2 个工具：query_departments（科室树）、query_slots（号源），复用已有 Service，回答基于真实数据。
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AiService {

    /** 注册给 DeepSeek 的工具列表（OpenAI function calling 格式） */
    private static final String TOOLS_JSON = """
            [
              {
                "type": "function",
                "function": {
                  "name": "query_departments",
                  "description": "查询医院全部科室（含一级、二级科室的ID和名称），用于把用户说的科室名映射成科室ID",
                  "parameters": { "type": "object", "properties": {}, "required": [] }
                }
              },
              {
                "type": "function",
                "function": {
                  "name": "query_slots",
                  "description": "查询指定二级科室、指定日期的可预约号源（医生、时段、余号、费用）。departmentId 必须先通过 query_departments 查科室树得到，不能猜测",
                  "parameters": {
                    "type": "object",
                    "properties": {
                      "departmentId": { "type": "integer", "description": "二级科室ID（通过 query_departments 查询得到）" },
                      "date": { "type": "string", "description": "就诊日期，必须用 yyyy-MM-dd 格式，例如 2026-09-07" }
                    },
                    "required": [ "departmentId", "date" ]
                  }
                }
              }
            ]
            """;

    private static final Duration CONNECT_TIMEOUT = Duration.ofSeconds(10);
    private static final Duration READ_TIMEOUT = Duration.ofSeconds(60);
    /** 最多让模型连续调用工具多少轮，防止死循环 */
    private static final int MAX_TOOL_ROUNDS = 5;

    private final ObjectMapper objectMapper;
    private final DepartmentService departmentService;
    private final ScheduleSlotService scheduleSlotService;
    private final AiConversationMapper aiConversationMapper;
    private final AiMessageMapper aiMessageMapper;

    /** 每次调用模型最多携带多少条历史消息，防止上下文过长 */
    private static final int HISTORY_LIMIT = 20;

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(CONNECT_TIMEOUT)
            .build();

    @Value("${app.ai.deepseek.api-key:}")
    private String apiKey;

    @Value("${app.ai.deepseek.base-url:https://api.deepseek.com}")
    private String baseUrl;

    @Value("${app.ai.deepseek.model:deepseek-chat}")
    private String model;

    public ChatResponse chat(List<ChatMessage> messages) {
        if (apiKey == null || apiKey.isBlank()) {
            throw new BusinessException(ErrorCode.BUSINESS_RULE_VIOLATION,
                    "AI 服务未配置 API Key，请在后端配置后重试");
        }

        List<Map<String, Object>> apiMessages = new ArrayList<>();
        apiMessages.add(Map.of("role", "system", "content", systemPrompt()));
        for (ChatMessage m : messages) {
            String role = "assistant".equals(m.role()) ? "assistant" : "user";
            apiMessages.add(Map.of("role", role, "content", m.content() == null ? "" : m.content()));
        }

        List<SlotSummary> collectedSlots = new ArrayList<>();
        String reply = null;
        try {
            for (int round = 0; round < MAX_TOOL_ROUNDS; round++) {
                JsonNode responseJson = call(apiMessages);
                JsonNode messageNode = responseJson.path("choices").get(0).path("message");
                JsonNode toolCalls = messageNode.path("tool_calls");

                // 模型请求调用工具：原样保留 assistant 的 tool_calls 消息，逐个执行工具并追加结果
                if (toolCalls.isArray() && !toolCalls.isEmpty()) {
                    apiMessages.add(objectMapper.convertValue(messageNode, new TypeReference<Map<String, Object>>() {}));
                    for (JsonNode tc : toolCalls) {
                        String id = tc.path("id").asText("");
                        String name = tc.path("function").path("name").asText("");
                        String args = tc.path("function").path("arguments").asText("");
                        if (args == null || args.isBlank()) {
                            args = "{}";
                        }
                        apiMessages.add(toolMessage(id, executeTool(name, args, collectedSlots)));
                    }
                    continue;
                }

                String content = messageNode.path("content").asText("");
                if (!content.isBlank()) {
                    reply = content.trim();
                    break;
                }
                throw new BusinessException(ErrorCode.BUSINESS_RULE_VIOLATION, "AI 返回内容为空，请重试");
            }
        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            log.error("调用 DeepSeek 失败", e);
            throw new BusinessException(ErrorCode.BUSINESS_RULE_VIOLATION, "AI 服务暂时不可用，请稍后重试");
        }

        if (reply == null || reply.isBlank()) {
            throw new BusinessException(ErrorCode.BUSINESS_RULE_VIOLATION, "AI 处理超时，请重新提问");
        }
        return new ChatResponse(null, reply, collectedSlots);
    }

    /* ==================== 会话持久化：完整多会话管理 ==================== */

    /**
     * 会话内对话（落库版）：保存用户消息 → 按会话加载历史（最近 {@link #HISTORY_LIMIT} 条）
     * → 调模型 → 保存 AI 回复（号源卡片写入 extra_json，重开会话可还原卡片）。
     * conversationId 为空时自动新建会话（标题取首条内容前 20 字），并回传 conversationId。
     */
    public ChatResponse chatInConversation(Long userId, Long conversationId, String content) {
        AiConversation conversation;
        if (conversationId == null) {
            conversation = new AiConversation();
            conversation.setUserId(userId);
            conversation.setTitle(buildTitle(content));
            aiConversationMapper.insert(conversation);
        } else {
            conversation = requireConversation(userId, conversationId);
        }

        saveMessage(conversation.getId(), "USER", content, null);

        ChatResponse out = chat(loadHistory(conversation.getId()));

        saveMessage(conversation.getId(), "ASSISTANT", out.reply(), out.slots());

        conversation.setLastMessageAt(LocalDateTime.now());
        aiConversationMapper.updateById(conversation);

        return new ChatResponse(conversation.getId(), out.reply(), out.slots());
    }

    /** 会话列表：按最后消息时间倒序 */
    public List<ConversationItem> listConversations(Long userId) {
        return aiConversationMapper.selectList(new LambdaQueryWrapper<AiConversation>()
                        .eq(AiConversation::getUserId, userId)
                        .orderByDesc(AiConversation::getLastMessageAt)
                        .orderByDesc(AiConversation::getCreatedAt))
                .stream()
                .map(c -> new ConversationItem(c.getId(), c.getTitle(), c.getLastMessageAt()))
                .toList();
    }

    /** 新建空会话（标题"新对话"，首次对话时由 chatInConversation 落消息） */
    public ConversationItem createConversation(Long userId) {
        AiConversation conversation = new AiConversation();
        conversation.setUserId(userId);
        conversation.setTitle("新对话");
        aiConversationMapper.insert(conversation);
        return new ConversationItem(conversation.getId(), conversation.getTitle(), conversation.getLastMessageAt());
    }

    /** 删除会话（逻辑删除，仅能删除自己的） */
    public void deleteConversation(Long userId, Long conversationId) {
        requireConversation(userId, conversationId);
        aiConversationMapper.deleteById(conversationId);
    }

    /** 会话历史消息：按时间升序；ASSISTANT 消息附带 extra_json 解析出的号源卡片 */
    public List<AiMessageItem> listMessages(Long userId, Long conversationId) {
        requireConversation(userId, conversationId);
        return aiMessageMapper.selectList(new LambdaQueryWrapper<AiMessage>()
                        .eq(AiMessage::getConversationId, conversationId)
                        .orderByAsc(AiMessage::getCreatedAt)
                        .orderByAsc(AiMessage::getId))
                .stream()
                .map(this::toMessageItem)
                .toList();
    }

    private AiMessageItem toMessageItem(AiMessage message) {
        List<SlotSummary> slots = null;
        if (message.getExtraJson() != null && !message.getExtraJson().isBlank()) {
            try {
                slots = objectMapper.readValue(message.getExtraJson(), new TypeReference<List<SlotSummary>>() {});
            } catch (Exception e) {
                log.warn("解析 AI 消息 extra_json 失败 id={}", message.getId(), e);
            }
        }
        return new AiMessageItem(message.getId(), message.getRole(), message.getContent(), slots, message.getCreatedAt());
    }

    /** 校验会话存在且属于当前用户 */
    private AiConversation requireConversation(Long userId, Long conversationId) {
        AiConversation conversation = aiConversationMapper.selectById(conversationId);
        if (conversation == null || !userId.equals(conversation.getUserId())) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "会话不存在");
        }
        return conversation;
    }

    private void saveMessage(Long conversationId, String role, String content, List<SlotSummary> slots) {
        AiMessage message = new AiMessage();
        message.setConversationId(conversationId);
        message.setRole(role);
        message.setContent(content);
        if (slots != null && !slots.isEmpty()) {
            try {
                message.setExtraJson(objectMapper.writeValueAsString(slots));
            } catch (Exception e) {
                log.warn("序列化号源卡片失败 conversationId={}", conversationId, e);
            }
        }
        aiMessageMapper.insert(message);
    }

    /** 从库里加载会话历史（最近 HISTORY_LIMIT 条），只带 USER/ASSISTANT 两种角色进模型 */
    private List<ChatMessage> loadHistory(Long conversationId) {
        List<AiMessage> all = aiMessageMapper.selectList(new LambdaQueryWrapper<AiMessage>()
                .eq(AiMessage::getConversationId, conversationId)
                .orderByAsc(AiMessage::getCreatedAt)
                .orderByAsc(AiMessage::getId));
        if (all.size() > HISTORY_LIMIT) {
            all = all.subList(all.size() - HISTORY_LIMIT, all.size());
        }
        List<ChatMessage> history = new ArrayList<>();
        for (AiMessage m : all) {
            String role = "ASSISTANT".equals(m.getRole()) ? "assistant" : ("USER".equals(m.getRole()) ? "user" : null);
            if (role == null) {
                continue;
            }
            history.add(new ChatMessage(role, m.getContent()));
        }
        return history;
    }

    /** 会话标题：首条内容前 20 字 */
    private String buildTitle(String content) {
        String t = content == null ? "" : content.trim().replaceAll("\\s+", " ");
        if (t.isEmpty()) {
            return "新对话";
        }
        return t.length() > 20 ? t.substring(0, 20) : t;
    }

    private String systemPrompt() {
        return "你是“东软云医院”的 AI 导诊助手。你可以根据用户的症状描述推荐合适的就诊科室，"
                + "解答挂号、就诊流程、科室/医生信息等问题，并引导用户完成在线预约挂号。"
                + "今天是 " + LocalDate.now() + "。"
                + "当用户询问科室、号源、能否挂号等问题时，必须调用提供的工具查询真实数据后再回答，不要编造。"
                + "查询号源前，必须先调用 query_departments 拿到科室ID；日期一律换算成 yyyy-MM-dd 格式；"
                + "调用 query_slots 时 departmentId 和 date 两个参数都必须提供，不要省略。"
                + "金额字段 feeFen 单位是分，展示给用户时除以 100 得到元。"
                + "回答用简洁、专业、友好的中文，重点直接给出建议，尽量控制在 200 字以内；"
                + "如遇胸痛、大出血、呼吸困难等急危重症，请提醒用户立即就医或拨打急救电话。"
                + "查到号源后，可在回答末尾询问用户是否需要帮忙预约。";
    }

    private Map<String, Object> toolMessage(String id, String content) {
        Map<String, Object> m = new HashMap<>();
        m.put("role", "tool");
        m.put("tool_call_id", id);
        m.put("content", content);
        return m;
    }

    /** 发一次 chat.completions 请求，返回完整响应 JSON（非 2xx 抛业务异常） */
    private JsonNode call(List<Map<String, Object>> apiMessages) throws Exception {
        Map<String, Object> body = new HashMap<>();
        body.put("model", model);
        body.put("messages", apiMessages);
        body.put("tools", objectMapper.readTree(TOOLS_JSON));
        body.put("stream", false);
        body.put("temperature", 0.3);
        body.put("max_tokens", 1024);

        String json = objectMapper.writeValueAsString(body);
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(baseUrl + "/chat/completions"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + apiKey)
                .timeout(READ_TIMEOUT)
                .POST(HttpRequest.BodyPublishers.ofString(json))
                .build();
        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

        String raw = response.body();
        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            JsonNode root = raw == null || raw.isBlank() ? objectMapper.createObjectNode() : objectMapper.readTree(raw);
            JsonNode error = root.path("error");
            String msg = error.hasNonNull("message") ? error.path("message").asText() : ("HTTP " + response.statusCode());
            log.error("DeepSeek 返回错误：{}", raw);
            throw new BusinessException(ErrorCode.BUSINESS_RULE_VIOLATION, "AI 服务异常：" + msg);
        }

        if (raw == null || raw.isBlank()) {
            throw new BusinessException(ErrorCode.BUSINESS_RULE_VIOLATION, "AI 返回内容为空，请重试");
        }
        return objectMapper.readTree(raw);
    }

    /** 执行工具调用，返回结果字符串（JSON 或说明文本） */
    private String executeTool(String name, String argumentsJson, List<SlotSummary> collectedSlots) {
        log.info("AI 调用工具 name={} args={}", name, argumentsJson);
        try {
            JsonNode args = objectMapper.readTree(argumentsJson);
            switch (name) {
                case "query_departments":
                    return formatDepartments(departmentService.tree());
                case "query_slots":
                    return executeQuerySlots(args, collectedSlots);
                default:
                    return "未知工具：" + name;
            }
        } catch (Exception e) {
            log.warn("AI 工具调用失败 name={} args={}", name, argumentsJson, e);
            return "工具调用失败：" + e.getMessage();
        }
    }

    private String executeQuerySlots(JsonNode args, List<SlotSummary> collectedSlots) throws Exception {
        if (args == null || !args.hasNonNull("departmentId") || !args.hasNonNull("date")) {
            return "缺少参数：调用 query_slots 必须同时提供 departmentId 和 date，请先调用 query_departments 查科室ID";
        }
        long departmentId = args.path("departmentId").asLong(0);
        if (departmentId <= 0) {
            return "departmentId 无效：" + departmentId;
        }
        String dateStr = args.path("date").asText("");
        LocalDate date = parseDate(dateStr);
        if (date == null) {
            return "日期格式不正确：" + dateStr + "，请使用 yyyy-MM-dd 格式，例如 2026-09-07";
        }
        List<SlotSummary> slots = scheduleSlotService.query(departmentId, date, null);
        collectedSlots.clear();
        collectedSlots.addAll(slots);
        return formatSlots(slots);
    }

    /** 宽容解析日期：兼容 yyyy-MM-dd / yyyy-M-d / yyyy/MM/dd 等常见写法 */
    private LocalDate parseDate(String s) {
        String t = s == null ? "" : s.trim().replace('/', '-');
        if (t.isBlank()) {
            return null;
        }
        try {
            return LocalDate.parse(t, DateTimeFormatter.ofPattern("uuuu-M-d"));
        } catch (Exception e) {
            return null;
        }
    }

    private String formatDepartments(List<DepartmentTreeNode> tree) throws Exception {
        List<Map<String, Object>> list = new ArrayList<>();
        for (DepartmentTreeNode l1 : tree) {
            Map<String, Object> m = new HashMap<>();
            m.put("id", l1.id());
            m.put("name", l1.name());
            List<Map<String, Object>> kids = new ArrayList<>();
            if (l1.children() != null) {
                for (DepartmentTreeNode l2 : l1.children()) {
                    Map<String, Object> k = new HashMap<>();
                    k.put("id", l2.id());
                    k.put("name", l2.name());
                    kids.add(k);
                }
            }
            m.put("children", kids);
            list.add(m);
        }
        return objectMapper.writeValueAsString(list);
    }

    private String formatSlots(List<SlotSummary> slots) throws Exception {
        if (slots == null || slots.isEmpty()) {
            return "该科室该日期暂无号源";
        }
        List<Map<String, Object>> list = new ArrayList<>();
        for (SlotSummary s : slots) {
            Map<String, Object> m = new HashMap<>();
            m.put("slotId", String.valueOf(s.slotId()));
            m.put("doctorName", s.doctorName());
            m.put("levelName", s.levelName());
            m.put("feeFen", s.feeFen());
            m.put("visitDate", s.visitDate() == null ? null : s.visitDate().toString());
            m.put("startTime", s.startTime() == null ? null : s.startTime().toString());
            m.put("endTime", s.endTime() == null ? null : s.endTime().toString());
            m.put("remainingQuota", s.remainingQuota());
            list.add(m);
        }
        return objectMapper.writeValueAsString(list);
    }
}
