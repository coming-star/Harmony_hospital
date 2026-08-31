package com.neusoft.hisspringboot;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@MapperScan("com.neusoft.hisspringboot.modules.**.mapper")
@SpringBootApplication
public class HisSpringbootApplication {

    public static void main(String[] args) {
        SpringApplication.run(HisSpringbootApplication.class, args);
    }
}