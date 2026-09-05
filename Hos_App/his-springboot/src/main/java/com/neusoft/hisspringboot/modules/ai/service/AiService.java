package com.neusoft.hisspringboot.modules.ai.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.neusoft.hisspringboot.common.BusinessException;
import com.neusoft.hisspringboot.common.ErrorCode;
import com.neusoft.hisspringboot.modules.ai.dto.ChatMessage;
import com.neusoft.hisspringboot.modules.ai.dto.ChatResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * AI 导诊：调用 DeepSeek（OpenAI 兼容）chat/completions 接口。
 * 使用 JDK 内置 HttpClient，无需额外依赖；API Key 由后端配置，前端不接触。
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AiService {

    private static final String SYSTEM_PROMPT =
            "你是“东软云医院”的 AI 导诊助手。你可以根据用户的症状描述推荐合适的就诊科室，"
          + "解答挂号、就诊流程、科室/医生信息等问题，并引导用户完成在线预约挂号。"
          + "请用简洁、专业、友好的中文回答，重点直接给出建议，尽量控制在 200 字以内；"
          + "如遇胸痛、大出血、呼吸困难等急危重症，请提醒用户立即就医或拨打急救电话。";

    private static final Duration CONNECT_TIMEOUT = Duration.ofSeconds(10);
    private static final Duration READ_TIMEOUT = Duration.ofSeconds(60);

    private final ObjectMapper objectMapper;

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

        // 组装 messages：system 提示 + 历史对话
        List<Map<String, String>> apiMessages = new ArrayList<>();
        apiMessages.add(Map.of("role", "system", "content", SYSTEM_PROMPT));
        for (ChatMessage m : messages) {
            String role = "assistant".equals(m.role()) ? "assistant" : "user";
            String content = m.content() == null ? "" : m.content();
            apiMessages.add(Map.of("role", role, "content", content));
        }

        Map<String, Object> body = new HashMap<>();
        body.put("model", model);
        body.put("messages", apiMessages);
        body.put("stream", false);
        body.put("temperature", 0.7);
        body.put("max_tokens", 1024);

        try {
            String json = objectMapper.writeValueAsString(body);
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(baseUrl + "/chat/completions"))
                    .header("Content-Type", "application/json")
                    .header("Authorization", "Bearer " + apiKey)
                    .timeout(READ_TIMEOUT)
                    .POST(HttpRequest.BodyPublishers.ofString(json))
                    .build();
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            return new ChatResponse(parseReply(response));
        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            log.error("调用 DeepSeek 失败", e);
            throw new BusinessException(ErrorCode.BUSINESS_RULE_VIOLATION,
                    "AI 服务暂时不可用，请稍后重试");
        }
    }

    private String parseReply(HttpResponse<String> response) throws Exception {
        String raw = response.body();
        if (raw == null || raw.isBlank()) {
            throw new BusinessException(ErrorCode.BUSINESS_RULE_VIOLATION, "AI 返回内容为空，请重试");
        }
        JsonNode root = objectMapper.readTree(raw);

        if (response.statusCode() >= 200 && response.statusCode() < 300) {
            JsonNode choices = root.get("choices");
            if (choices != null && choices.isArray() && !choices.isEmpty()) {
                JsonNode message = choices.get(0).get("message");
                if (message != null && message.hasNonNull("content")) {
                    String content = message.get("content").asText().trim();
                    if (!content.isEmpty()) {
                        return content;
                    }
                }
            }
            throw new BusinessException(ErrorCode.BUSINESS_RULE_VIOLATION, "AI 返回内容为空，请重试");
        }

        JsonNode error = root.get("error");
        String msg = (error != null && error.hasNonNull("message"))
                ? error.get("message").asText()
                : ("HTTP " + response.statusCode());
        log.error("DeepSeek 返回错误：{}", raw);
        throw new BusinessException(ErrorCode.BUSINESS_RULE_VIOLATION, "AI 服务异常：" + msg);
    }
}
