package com.neusoft.hisspringboot.common;

import io.swagger.v3.oas.annotations.media.Schema;

import java.util.List;

/**
 * 分页响应包装体：列表接口统一返回 {records, total, page, size}。
 *
 * @param records 当前页数据列表
 * @param total   总记录数
 * @param page    当前页码（从 1 开始）
 * @param size    每页条数
 */
@Schema(description = "分页响应结果")
public record PageResult<T>(
        @Schema(description = "当前页数据列表")
        List<T> records,

        @Schema(description = "总记录数", example = "13")
        long total,

        @Schema(description = "当前页码，从 1 开始", example = "1")
        int page,

        @Schema(description = "每页条数", example = "10")
        int size
) {

    public static <T> PageResult<T> of(List<T> records, long total, int page, int size) {
        return new PageResult<>(records, total, page, size);
    }
}
