package com.neusoft.hisspringboot.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI hospitalOpenApi() {
        return new OpenAPI()
                .info(new Info()
                        .title("东软云医院预约挂号系统 API")
                        .description("包含系统管理员后台和鸿蒙 App 患者端接口。")
                        .version("v1.0.0"))
                .components(new Components()
                        .addSecuritySchemes(
                                HttpHeaders.AUTHORIZATION,
                                new SecurityScheme()
                                        .name(HttpHeaders.AUTHORIZATION)
                                        .type(SecurityScheme.Type.HTTP)
                                        .scheme("bearer")
                                        .bearerFormat("JWT")
                                        .description("填写登录接口返回的 accessToken")
                        ));
    }
}