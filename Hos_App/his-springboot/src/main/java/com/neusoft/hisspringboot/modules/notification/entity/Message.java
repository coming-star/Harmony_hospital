package com.neusoft.hisspringboot.modules.notification.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 站内信（消息中心）：订单状态通知（预约成功/取消/超时取消）与就诊提醒共用一张表。
 * dedup_key 唯一索引做幂等防重：同一订单同一事件/同一提醒时点只写一条。
 */
@Data
@TableName("message")
public class Message {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    /** 消息归属的登录账号 */
    private Long userId;

    /** 消息类型：ORDER_PAY_SUCCESS/ORDER_CANCELLED/ORDER_TIMEOUT/VISIT_REMINDER */
    private String type;

    /** 消息标题，列表页直接展示 */
    private String title;

    /** 消息正文 */
    private String content;

    /** 关联业务ID（一般是订单ID），点击可跳订单详情 */
    private Long bizId;

    /** 防重键：订单事件为 "事件类型:订单ID"，就诊提醒为 "订单ID:REMIND_24H/REMIND_3H" */
    private String dedupKey;

    /** 是否已读：0未读 1已读 */
    private Integer isRead;

    private LocalDateTime createdAt;
}
