package com.neusoft.hisspringboot;

import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

/**
 * 应用启动完成后打印成功提示，方便本地开发时快速确认后端已就绪。
 */
@Slf4j
@Component
public class StartupSuccessRunner implements ApplicationRunner {

    @Override
    public void run(ApplicationArguments args) {
        log.info("===============================================");
        log.info("  东软云医院挂号预约系统后端启动成功！");
        log.info("  接口文档: http://localhost:8081/doc.html");
        log.info("===============================================");
    }
}
