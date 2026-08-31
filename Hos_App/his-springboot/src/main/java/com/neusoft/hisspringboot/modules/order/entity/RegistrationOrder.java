package com.neusoft.hisspringboot.modules.order.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

@Data
@TableName("registration_order")
public class RegistrationOrder {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    private String orderNo;
    private Long userId;
    private Long contactId;
    private Long slotId;
    private Long doctorId;
    private Long departmentId;
    private Long levelId;
    private String doctorNameSnapshot;
    private String departmentNameSnapshot;
    private String levelNameSnapshot;
    private LocalDate visitDate;
    private LocalTime startTime;
    private LocalTime endTime;
    private Integer amountFen;

    /**
     * PENDING_PAYMENT/PAID/CANCELLED/COMPLETED。
     */
    private String status;

    private LocalDateTime expiredAt;
    private LocalDateTime paidAt;
    private LocalDateTime cancelledAt;
    private String cancelReason;
    private String idempotencyKey;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
