package com.neusoft.hisspringboot.modules.contact.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

/**
 * 患者端新增/修改就诊人请求。
 * relation 为空时后端默认按 SELF（本人）处理。
 */
@Schema(description = "新增/修改就诊人请求")
public record ContactRequest(

        @Schema(description = "就诊人姓名", example = "张建国", requiredMode = Schema.RequiredMode.REQUIRED)
        @NotBlank(message = "就诊人姓名不能为空")
        String name,

        @Schema(description = "就诊人手机号（11 位，1 开头）", example = "13900000002", requiredMode = Schema.RequiredMode.REQUIRED)
        @NotBlank(message = "手机号不能为空")
        @Pattern(regexp = "^1\\d{10}$", message = "手机号格式不正确")
        String phone,

        @Schema(description = "与账号本人的关系：SELF本人/PARENT父母/CHILD子女/SPOUSE配偶/OTHER其他，不传默认 SELF",
                example = "PARENT", allowableValues = {"SELF", "PARENT", "CHILD", "SPOUSE", "OTHER"})
        @Pattern(regexp = "SELF|PARENT|CHILD|SPOUSE|OTHER",
                message = "关系只能是 SELF/PARENT/CHILD/SPOUSE/OTHER")
        String relation
) {
}
