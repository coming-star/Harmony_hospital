package com.neusoft.hisspringboot.modules.order.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("payment_record")
public class PaymentRecord {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    private Long orderId;

    /**
     * 本期固定 MOCK。
     */
    private String channel;

    private String tradeNo;
    private Integer amountFen;

    /**
     * INIT/SUCCESS/FAILED/CLOSED。
     */
    private String status;

    private LocalDateTime paidAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
