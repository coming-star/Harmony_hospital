package com.neusoft.hisspringboot.modules.order.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.neusoft.hisspringboot.common.BusinessException;
import com.neusoft.hisspringboot.common.ErrorCode;
import com.neusoft.hisspringboot.common.PageResult;
import com.neusoft.hisspringboot.modules.contact.entity.PatientContact;
import com.neusoft.hisspringboot.modules.contact.mapper.PatientContactMapper;
import com.neusoft.hisspringboot.modules.department.entity.Department;
import com.neusoft.hisspringboot.modules.department.mapper.DepartmentMapper;
import com.neusoft.hisspringboot.modules.doctor.entity.Doctor;
import com.neusoft.hisspringboot.modules.doctor.mapper.DoctorMapper;
import com.neusoft.hisspringboot.modules.level.entity.RegistrationLevel;
import com.neusoft.hisspringboot.modules.level.mapper.RegistrationLevelMapper;
import com.neusoft.hisspringboot.modules.order.dto.CreateOrderRequest;
import com.neusoft.hisspringboot.modules.order.dto.DailyCount;
import com.neusoft.hisspringboot.modules.order.dto.DepartmentCount;
import com.neusoft.hisspringboot.modules.order.dto.OrderDetail;
import com.neusoft.hisspringboot.modules.order.entity.PaymentRecord;
import com.neusoft.hisspringboot.modules.order.entity.RegistrationOrder;
import com.neusoft.hisspringboot.modules.order.mapper.PaymentRecordMapper;
import com.neusoft.hisspringboot.modules.order.mapper.RegistrationOrderMapper;
import com.neusoft.hisspringboot.modules.schedule.entity.ScheduleSlot;
import com.neusoft.hisspringboot.modules.schedule.mapper.ScheduleSlotMapper;
import com.neusoft.hisspringboot.modules.user.entity.SysUser;
import com.neusoft.hisspringboot.modules.user.mapper.SysUserMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 挂号订单核心流程；状态机与并发扣号约定见 docs/06-挂号流程与状态机.md。
 * 15 分钟超时取消暂由 {@link com.neusoft.hisspringboot.modules.order.task.OrderTimeoutTask} 定时扫描实现，
 * 待 RocketMQ 接入后替换为延迟消息消费者，取消逻辑本身不受影响。
 */
@Service
@RequiredArgsConstructor
public class OrderService {

    private static final String STATUS_OPEN = "OPEN";
    private static final String STATUS_PENDING_PAYMENT = "PENDING_PAYMENT";
    private static final String STATUS_PAID = "PAID";
    private static final String STATUS_CANCELLED = "CANCELLED";

    private static final String CANCEL_SOURCE_USER = "USER";
    private static final String CANCEL_SOURCE_ADMIN = "ADMIN";
    private static final String CANCEL_SOURCE_TIMEOUT = "TIMEOUT";

    private static final int TIMEOUT_MINUTES = 15;

    private final RegistrationOrderMapper orderMapper;
    private final PaymentRecordMapper paymentRecordMapper;
    private final ScheduleSlotMapper scheduleSlotMapper;
    private final PatientContactMapper patientContactMapper;
    private final DoctorMapper doctorMapper;
    private final DepartmentMapper departmentMapper;
    private final RegistrationLevelMapper registrationLevelMapper;
    private final SysUserMapper sysUserMapper;

    @Transactional
    public OrderDetail createOrder(Long userId, CreateOrderRequest request) {
        RegistrationOrder existing = orderMapper.selectOne(
                new LambdaQueryWrapper<RegistrationOrder>()
                        .eq(RegistrationOrder::getUserId, userId)
                        .eq(RegistrationOrder::getIdempotencyKey, request.idempotencyKey())
        );

        if (existing != null) {
            return toDetail(existing);
        }

        PatientContact contact = patientContactMapper.selectOne(
                new LambdaQueryWrapper<PatientContact>()
                        .eq(PatientContact::getId, request.contactId())
                        .eq(PatientContact::getUserId, userId)
        );

        if (contact == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "就诊人不存在");
        }

        ScheduleSlot slot = scheduleSlotMapper.selectById(request.slotId());

        if (slot == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "预约时段不存在");
        }

        int updatedRows = scheduleSlotMapper.update(null,
                new LambdaUpdateWrapper<ScheduleSlot>()
                        .setSql("remaining_quota = remaining_quota - 1, version = version + 1")
                        .eq(ScheduleSlot::getId, slot.getId())
                        .eq(ScheduleSlot::getStatus, STATUS_OPEN)
                        .gt(ScheduleSlot::getRemainingQuota, 0)
                        .eq(ScheduleSlot::getVersion, slot.getVersion())
        );

        if (updatedRows == 0) {
            throw new BusinessException(ErrorCode.SLOT_SOLD_OUT);
        }

        RegistrationOrder order = buildOrder(userId, contact, slot, request.idempotencyKey());
        orderMapper.insert(order);

        PaymentRecord paymentRecord = new PaymentRecord();
        paymentRecord.setOrderId(order.getId());
        paymentRecord.setChannel("MOCK");
        paymentRecord.setAmountFen(order.getAmountFen());
        paymentRecord.setStatus("INIT");
        paymentRecordMapper.insert(paymentRecord);

        return toDetail(order);
    }

    @Transactional
    public OrderDetail pay(Long userId, Long orderId) {
        getOwnedOrder(userId, orderId);

        int rows = orderMapper.update(null,
                new LambdaUpdateWrapper<RegistrationOrder>()
                        .set(RegistrationOrder::getStatus, STATUS_PAID)
                        .set(RegistrationOrder::getPaidAt, LocalDateTime.now())
                        .eq(RegistrationOrder::getId, orderId)
                        .eq(RegistrationOrder::getUserId, userId)
                        .eq(RegistrationOrder::getStatus, STATUS_PENDING_PAYMENT)
        );

        RegistrationOrder current = orderMapper.selectById(orderId);

        if (rows == 0) {
            if (current != null && STATUS_PAID.equals(current.getStatus())) {
                return toDetail(current);
            }
            throw new BusinessException(ErrorCode.ORDER_STATUS_CONFLICT);
        }

        paymentRecordMapper.update(null,
                new LambdaUpdateWrapper<PaymentRecord>()
                        .set(PaymentRecord::getStatus, "SUCCESS")
                        .set(PaymentRecord::getPaidAt, LocalDateTime.now())
                        .set(PaymentRecord::getTradeNo, "MOCK" + orderId)
                        .eq(PaymentRecord::getOrderId, orderId)
        );

        return toDetail(current);
    }

    @Transactional
    public OrderDetail cancelByUser(Long userId, Long orderId) {
        getOwnedOrder(userId, orderId);
        return cancelInternal(orderId, CANCEL_SOURCE_USER);
    }

    /**
     * 供 {@link com.neusoft.hisspringboot.modules.order.task.OrderTimeoutTask} 调用；
     * 订单已被支付/取消时静默跳过，不视为异常。
     */
    @Transactional
    public void cancelByTimeout(Long orderId) {
        try {
            cancelInternal(orderId, CANCEL_SOURCE_TIMEOUT);
        } catch (BusinessException ignored) {
            // 订单在扫描间隙已被支付或取消，幂等跳过
        }
    }

    public PageResult<OrderDetail> list(Long userId, String status, int page, int size) {
        Page<RegistrationOrder> mpPage = orderMapper.selectPage(
                new Page<>(page, size),
                new LambdaQueryWrapper<RegistrationOrder>()
                        .eq(RegistrationOrder::getUserId, userId)
                        .eq(status != null && !status.isBlank(), RegistrationOrder::getStatus, status)
                        .orderByDesc(RegistrationOrder::getCreatedAt)
        );

        List<OrderDetail> records = mpPage.getRecords().stream().map(this::toDetail).toList();

        return PageResult.of(records, mpPage.getTotal(), page, size);
    }

    public OrderDetail detail(Long userId, Long orderId) {
        return toDetail(getOwnedOrder(userId, orderId));
    }

    /**
     * 后台"挂号记录"（WEB-08）分页查询；按订单号/患者手机号或姓名/就诊人姓名/医生姓名快照/日期/状态筛选。
     */
    public PageResult<OrderDetail> adminList(
            String orderNo,
            String patientKeyword,
            String doctorName,
            LocalDate visitDate,
            String status,
            int page,
            int size
    ) {
        LambdaQueryWrapper<RegistrationOrder> wrapper = new LambdaQueryWrapper<RegistrationOrder>()
                .like(orderNo != null && !orderNo.isBlank(), RegistrationOrder::getOrderNo, orderNo)
                .like(doctorName != null && !doctorName.isBlank(), RegistrationOrder::getDoctorNameSnapshot, doctorName)
                .eq(visitDate != null, RegistrationOrder::getVisitDate, visitDate)
                .eq(status != null && !status.isBlank(), RegistrationOrder::getStatus, status)
                .orderByDesc(RegistrationOrder::getCreatedAt);

        if (patientKeyword != null && !patientKeyword.isBlank()) {
            List<Long> contactIds = patientContactMapper.selectList(
                    new LambdaQueryWrapper<PatientContact>()
                            .like(PatientContact::getName, patientKeyword)
                            .or().like(PatientContact::getPhone, patientKeyword)
            ).stream().map(PatientContact::getId).toList();

            if (contactIds.isEmpty()) {
                return PageResult.of(List.of(), 0, page, size);
            }

            wrapper.in(RegistrationOrder::getContactId, contactIds);
        }

        Page<RegistrationOrder> mpPage = orderMapper.selectPage(new Page<>(page, size), wrapper);
        List<OrderDetail> records = mpPage.getRecords().stream().map(this::toDetail).toList();

        return PageResult.of(records, mpPage.getTotal(), page, size);
    }

    /**
     * 后台统计：近 7 天预约量趋势（按就诊日期，排除已取消，缺失日期补 0）。
     */
    public List<DailyCount> dailyTrend() {
        LocalDate end = LocalDate.now();
        LocalDate start = end.minusDays(6);

        Map<LocalDate, Long> counts = orderMapper.selectList(
                new LambdaQueryWrapper<RegistrationOrder>()
                        .ge(RegistrationOrder::getVisitDate, start)
                        .le(RegistrationOrder::getVisitDate, end)
                        .ne(RegistrationOrder::getStatus, STATUS_CANCELLED)
        ).stream().collect(Collectors.groupingBy(RegistrationOrder::getVisitDate, Collectors.counting()));

        List<DailyCount> result = new ArrayList<>();
        for (int i = 0; i < 7; i++) {
            LocalDate date = start.plusDays(i);
            result.add(new DailyCount(date, counts.getOrDefault(date, 0L)));
        }
        return result;
    }

    /**
     * 后台统计：近 7 天科室预约量 TOP5（按就诊日期，排除已取消）。
     */
    public List<DepartmentCount> departmentTop5() {
        LocalDate end = LocalDate.now();
        LocalDate start = end.minusDays(6);

        Map<String, Long> counts = orderMapper.selectList(
                new LambdaQueryWrapper<RegistrationOrder>()
                        .ge(RegistrationOrder::getVisitDate, start)
                        .le(RegistrationOrder::getVisitDate, end)
                        .ne(RegistrationOrder::getStatus, STATUS_CANCELLED)
        ).stream().collect(Collectors.groupingBy(
                order -> order.getDepartmentNameSnapshot() != null
                        ? order.getDepartmentNameSnapshot()
                        : String.valueOf(order.getDepartmentId()),
                Collectors.counting()
        ));

        return counts.entrySet().stream()
                .map(entry -> new DepartmentCount(entry.getKey(), entry.getValue()))
                .sorted(Comparator.comparingLong(DepartmentCount::count).reversed())
                .limit(5)
                .toList();
    }

    @Transactional
    public OrderDetail cancelByAdmin(Long orderId) {
        if (orderMapper.selectById(orderId) == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "挂号订单不存在");
        }

        return cancelInternal(orderId, CANCEL_SOURCE_ADMIN);
    }

    private OrderDetail cancelInternal(Long orderId, String cancelSource) {
        int rows = orderMapper.update(null,
                new LambdaUpdateWrapper<RegistrationOrder>()
                        .set(RegistrationOrder::getStatus, STATUS_CANCELLED)
                        .set(RegistrationOrder::getCancelledAt, LocalDateTime.now())
                        .set(RegistrationOrder::getCancelReason, cancelSource)
                        .eq(RegistrationOrder::getId, orderId)
                        .eq(RegistrationOrder::getStatus, STATUS_PENDING_PAYMENT)
        );

        RegistrationOrder current = orderMapper.selectById(orderId);

        if (rows == 1) {
            scheduleSlotMapper.update(null,
                    new LambdaUpdateWrapper<ScheduleSlot>()
                            .setSql("remaining_quota = remaining_quota + 1, version = version + 1")
                            .eq(ScheduleSlot::getId, current.getSlotId())
            );
            return toDetail(current);
        }

        if (current != null && STATUS_CANCELLED.equals(current.getStatus())) {
            return toDetail(current);
        }

        throw new BusinessException(ErrorCode.ORDER_STATUS_CONFLICT);
    }

    private RegistrationOrder getOwnedOrder(Long userId, Long orderId) {
        RegistrationOrder order = orderMapper.selectOne(
                new LambdaQueryWrapper<RegistrationOrder>()
                        .eq(RegistrationOrder::getId, orderId)
                        .eq(RegistrationOrder::getUserId, userId)
        );

        if (order == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "挂号订单不存在");
        }

        return order;
    }

    private RegistrationOrder buildOrder(
            Long userId,
            PatientContact contact,
            ScheduleSlot slot,
            String idempotencyKey
    ) {
        Doctor doctor = doctorMapper.selectById(slot.getDoctorId());
        Department department = departmentMapper.selectById(slot.getDepartmentId());
        RegistrationLevel level = registrationLevelMapper.selectById(slot.getLevelId());

        RegistrationOrder order = new RegistrationOrder();
        order.setOrderNo(generateOrderNo());
        order.setUserId(userId);
        order.setContactId(contact.getId());
        order.setSlotId(slot.getId());
        order.setDoctorId(slot.getDoctorId());
        order.setDepartmentId(slot.getDepartmentId());
        order.setLevelId(slot.getLevelId());
        order.setDoctorNameSnapshot(doctor == null ? null : doctor.getName());
        order.setDepartmentNameSnapshot(department == null ? null : department.getName());
        order.setLevelNameSnapshot(level == null ? null : level.getName());
        order.setVisitDate(slot.getVisitDate());
        order.setStartTime(slot.getStartTime());
        order.setEndTime(slot.getEndTime());
        order.setAmountFen(level == null ? 0 : level.getFeeFen());
        order.setStatus(STATUS_PENDING_PAYMENT);
        order.setExpiredAt(LocalDateTime.now().plusMinutes(TIMEOUT_MINUTES));
        order.setIdempotencyKey(idempotencyKey);

        return order;
    }

    private OrderDetail toDetail(RegistrationOrder order) {
        String contactName = null;
        String contactPhone = null;
        if (order.getContactId() != null) {
            PatientContact contact = patientContactMapper.selectById(order.getContactId());
            if (contact != null) {
                contactName = contact.getName();
                contactPhone = contact.getPhone();
            }
        }
        return new OrderDetail(
                order.getId(),
                order.getOrderNo(),
                order.getStatus(),
                order.getSlotId(),
                order.getDoctorId(),
                order.getDoctorNameSnapshot(),
                order.getDepartmentId(),
                order.getDepartmentNameSnapshot(),
                order.getLevelId(),
                order.getLevelNameSnapshot(),
                order.getVisitDate(),
                order.getStartTime(),
                order.getEndTime(),
                order.getAmountFen(),
                order.getExpiredAt(),
                order.getPaidAt(),
                order.getCancelledAt(),
                order.getCancelReason(),
                order.getCreatedAt(),
                contactName,
                contactPhone
        );
    }

    private String generateOrderNo() {
        String timestamp = DateTimeFormatter.ofPattern("yyyyMMddHHmmss").format(LocalDateTime.now());
        String random = String.valueOf(1000 + (int) (Math.random() * 9000));
        return "RG" + timestamp + random;
    }
}
