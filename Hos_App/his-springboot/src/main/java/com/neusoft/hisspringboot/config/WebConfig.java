package com.neusoft.hisspringboot.config;

import com.neusoft.hisspringboot.common.AesGcmUtil;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Path;

/**
 * Web 层配置：
 * 1. 注册 AES-GCM 加密工具 Bean（身份证加密）
 * 2. 把本地头像上传目录映射为可访问的静态资源路径 /static/avatars/**
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Value("${app.security.id-card-aes-key}")
    private String idCardAesKey;

    @Value("${app.upload.avatar-dir}")
    private String avatarDir;

    @Bean
    public AesGcmUtil aesGcmUtil() {
        return new AesGcmUtil(idCardAesKey);
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // 本地头像目录 → /static/avatars/**  URL，file: 协议末尾需加 /
        String location = Path.of(avatarDir).toAbsolutePath().toString().replace("\\", "/") + "/";
        registry.addResourceHandler("/static/avatars/**")
                .addResourceLocations("file:" + location);
    }
}
