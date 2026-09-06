package com.neusoft.hisspringboot.common;

import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Arrays;
import java.util.HexFormat;

/**
 * AES-GCM 对称加密工具（用于身份证号等敏感字段）+ SHA-256 哈希（用于判重）。
 *
 * 存储格式：varbinary 列存 [12 字节 IV][密文][16 字节 GCM Tag] 拼接结果，
 * 解密时取出前 12 字节作 IV，剩余部分交给 GCM 解密（自动校验 Tag）。
 *
 * 哈希用途：相同明文的 SHA-256 相同，可对身份证做"同账号下不重复"判重，
 * 同时不暴露明文。
 */
public final class AesGcmUtil {

    private static final String AES_GCM = "AES/GCM/NoPadding";
    private static final int IV_LEN = 12;
    private static final int TAG_BIT_LEN = 128; // 16 字节
    private static final SecureRandom RANDOM = new SecureRandom();

    private final SecretKeySpec keySpec;

    public AesGcmUtil(String hexKey) {
        byte[] keyBytes = HexFormat.of().parseHex(hexKey.trim());
        if (keyBytes.length != 16 && keyBytes.length != 24 && keyBytes.length != 32) {
            throw new IllegalArgumentException("AES key 必须为 16/24/32 字节（hex 32/48/64 字符）");
        }
        this.keySpec = new SecretKeySpec(keyBytes, "AES");
    }

    /** 加密：返回 IV+密文+Tag 拼接的字节数组 */
    public byte[] encrypt(String plain) {
        if (plain == null || plain.isBlank()) {
            return null;
        }
        try {
            byte[] iv = new byte[IV_LEN];
            RANDOM.nextBytes(iv);
            Cipher cipher = Cipher.getInstance(AES_GCM);
            cipher.init(Cipher.ENCRYPT_MODE, keySpec, new GCMParameterSpec(TAG_BIT_LEN, iv));
            byte[] cipherText = cipher.doFinal(plain.getBytes(java.nio.charset.StandardCharsets.UTF_8));
            byte[] result = new byte[IV_LEN + cipherText.length];
            System.arraycopy(iv, 0, result, 0, IV_LEN);
            System.arraycopy(cipherText, 0, result, IV_LEN, cipherText.length);
            return result;
        } catch (Exception e) {
            throw new IllegalStateException("AES-GCM 加密失败", e);
        }
    }

    /** 解密：传入 [IV+密文+Tag] 字节数组，返回明文 */
    public String decrypt(byte[] packed) {
        if (packed == null || packed.length <= IV_LEN) {
            return null;
        }
        try {
            byte[] iv = Arrays.copyOfRange(packed, 0, IV_LEN);
            byte[] cipherText = Arrays.copyOfRange(packed, IV_LEN, packed.length);
            Cipher cipher = Cipher.getInstance(AES_GCM);
            cipher.init(Cipher.DECRYPT_MODE, keySpec, new GCMParameterSpec(TAG_BIT_LEN, iv));
            byte[] plain = cipher.doFinal(cipherText);
            return new String(plain, java.nio.charset.StandardCharsets.UTF_8);
        } catch (Exception e) {
            throw new IllegalStateException("AES-GCM 解密失败（密钥不匹配或数据损坏）", e);
        }
    }

    /** SHA-256 哈希，返回 64 位 hex 字符串（用于判重，不可逆） */
    public static String sha256(String text) {
        if (text == null || text.isBlank()) {
            return null;
        }
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] digest = md.digest(text.getBytes(java.nio.charset.StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (Exception e) {
            throw new IllegalStateException("SHA-256 计算失败", e);
        }
    }
}
