package com.neusoft.hisspringboot.common;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * 统一响应包装体：所有接口返回 {code, message, data} 结构。
 *
 * @param code    响应编码：200 表示成功，其他为业务错误码
 * @param message 响应消息：成功为"操作成功"，失败为错误提示
 * @param data    响应数据：具体业务数据，失败时为 null
 */
@Schema(description = "统一响应结果")
public record ApiResponse<T>(
        @Schema(description = "响应编码：200 表示成功，其他为业务错误码", example = "200")
        Integer code,

        @Schema(description = "响应消息：成功为“操作成功”，失败为错误提示", example = "操作成功")
        String message,

        @Schema(description = "响应数据：具体业务数据，失败时为 null")
        T data
) {

    public static <T> ApiResponse<T> success(T data) {
        return new ApiResponse<>(200, "操作成功", data);
    }

    public static ApiResponse<Void> success() {
        return new ApiResponse<>(200, "操作成功", null);
    }

    public static ApiResponse<Void> fail(Integer code, String message) {
        return new ApiResponse<>(code, message, null);
    }

    public static ApiResponse<Void> fail(ErrorCode errorCode) {
        return new ApiResponse<>(errorCode.getCode(), errorCode.getMessage(), null);
    }
}
