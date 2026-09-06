package com.neusoft.hisspringboot.modules.common.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.common.BusinessException;
import com.neusoft.hisspringboot.common.ErrorCode;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.UUID;

/**
 * 文件上传接口（当前仅支持头像）。
 * 头像保存到本地目录，通过 /static/avatars/** 映射为可访问 URL。
 */
@Tag(name = "文件上传", description = "头像等文件上传")
@RestController
@RequestMapping("/api/upload")
@RequiredArgsConstructor
public class UploadController {

    private static final List<String> ALLOWED_EXTENSIONS = List.of("jpg", "jpeg", "png", "webp");

    @Value("${app.upload.avatar-dir}")
    private String avatarDir;

    @Value("${app.upload.avatar-url-prefix}")
    private String avatarUrlPrefix;

    @Operation(
            summary = "上传头像",
            description = "上传头像图片（jpg/jpeg/png/webp，最大 5MB），返回可直接访问的头像 URL",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PostMapping("/avatar")
    public ApiResponse<AvatarUploadResponse> uploadAvatar(
            @RequestParam("file") MultipartFile file
    ) {
        if (file == null || file.isEmpty()) {
            throw new BusinessException(ErrorCode.BUSINESS_RULE_VIOLATION, "请选择要上传的图片");
        }

        String original = file.getOriginalFilename();
        String ext = extractExtension(original);
        if (!ALLOWED_EXTENSIONS.contains(ext.toLowerCase())) {
            throw new BusinessException(ErrorCode.BUSINESS_RULE_VIOLATION,
                    "仅支持 jpg/jpeg/png/webp 格式图片");
        }

        String filename = UUID.randomUUID().toString().replace("-", "") + "." + ext;
        Path dir = Path.of(avatarDir);
        try {
            Files.createDirectories(dir);
            file.transferTo(dir.resolve(filename).toFile());
        } catch (IOException e) {
            throw new BusinessException(ErrorCode.BUSINESS_RULE_VIOLATION, "头像保存失败：" + e.getMessage());
        }

        String url = avatarUrlPrefix + "/" + filename;
        return ApiResponse.success(new AvatarUploadResponse(url));
    }

    private String extractExtension(String filename) {
        if (filename == null || filename.isEmpty()) {
            return "";
        }
        int idx = filename.lastIndexOf('.');
        return idx >= 0 ? filename.substring(idx + 1) : "";
    }

    public record AvatarUploadResponse(
            @Schema(description = "头像访问 URL", example = "http://localhost:8081/static/avatars/abc123.png")
            String url
    ) {
    }
}
