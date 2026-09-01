package com.neusoft.hisspringboot.common;

import org.springframework.http.HttpStatus;

/**
 * 业务错误码目录，配合 {@link GlobalExceptionHandler} 使用。
 * 框架级错误（参数校验、未捕获异常等）沿用 HTTP 状态码作为 code；
 * 本枚举用于需要区分具体业务场景的错误，详见 docs/07-RESTful接口契约.md。
 */
public enum ErrorCode {

    PHONE_ALREADY_REGISTERED(409001, HttpStatus.CONFLICT, "手机号已注册"),
    CONTACT_ID_CARD_DUPLICATED(409002, HttpStatus.CONFLICT, "该身份证已绑定其他就诊人"),
    SLOT_SOLD_OUT(409003, HttpStatus.CONFLICT, "该时段已约满或状态已变化"),
    ORDER_STATUS_CONFLICT(409004, HttpStatus.CONFLICT, "订单状态已变化，操作不可执行"),
    REFERENCED_BY_OTHER_RECORD(409005, HttpStatus.CONFLICT, "存在关联数据引用，请先停用"),
    CODE_ALREADY_EXISTS(409006, HttpStatus.CONFLICT, "编码已存在"),
    BUSINESS_RULE_VIOLATION(422001, HttpStatus.UNPROCESSABLE_ENTITY, "业务规则校验未通过");

    private final int code;
    private final HttpStatus httpStatus;
    private final String message;

    ErrorCode(int code, HttpStatus httpStatus, String message) {
        this.code = code;
        this.httpStatus = httpStatus;
        this.message = message;
    }

    public int getCode() {
        return code;
    }

    public HttpStatus getHttpStatus() {
        return httpStatus;
    }

    public String getMessage() {
        return message;
    }
}
