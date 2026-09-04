<script setup>
import { reactive, ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { adminLogin } from '../api/auth'
import { useAuthStore } from '../store/auth'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

const formRef = ref()
const loading = ref(false)

const form = reactive({
  username: '',
  password: '',
})

const rules = {
  username: [{ required: true, message: '请输入管理员账号', trigger: 'blur' }],
  password: [{ required: true, message: '请输入密码', trigger: 'blur' }],
}

async function handleSubmit() {
  await formRef.value.validate()
  loading.value = true
  try {
    const loginResponse = await adminLogin(form)
    authStore.setSession(loginResponse)
    router.push(route.query.redirect || '/dashboard')
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="login-page">
    <div class="login-box">
      <h1 class="login-title">欢迎来到东软云医院</h1>

      <el-form
        ref="formRef"
        :model="form"
        :rules="rules"
        label-position="top"
        class="login-form"
        @keyup.enter="handleSubmit"
      >
        <el-form-item label="username" prop="username" class="login-form-item">
          <el-input v-model="form.username" class="login-input" />
        </el-form-item>
        <el-form-item label="password" prop="password" class="login-form-item">
          <el-input v-model="form.password" type="password" show-password class="login-input" />
        </el-form-item>
        <el-form-item class="login-btn-item">
          <el-button class="login-btn" :loading="loading" @click="handleSubmit">登录</el-button>
        </el-form-item>
      </el-form>
    </div>
  </div>
</template>

<style scoped>
.login-page {
  height: 100vh;
  display: flex;
  align-items: center;
  background: url('../assets/login-bg-4.jpg') center / cover no-repeat;
}

.login-box {
  width: 360px;
  margin-left: 11%;
  padding: 0;
  background: transparent;
}

.login-title {
  margin: 0;
  font-size: 32px;
  font-weight: 700;
  color: #ffffff;
  line-height: 1.2;
}

.login-form {
  margin-top: 44px;
}

.login-form-item {
  margin-bottom: 24px;
}

.login-form-item :deep(.el-form-item__label) {
  color: rgba(255, 255, 255, 0.7);
  font-size: 14px;
  font-weight: 400;
  line-height: 1.2;
  margin-bottom: 0;
  padding-bottom: 4px;
}

.login-input {
  --el-input-height: 48px;
}

.login-input :deep(.el-input__wrapper) {
  background: transparent;
  box-shadow: none;
  border-bottom: 1px solid rgba(255, 255, 255, 0.6);
  border-radius: 0;
  padding: 0;
  transition: border-bottom-color 0.2s ease;
}

.login-input :deep(.el-input__wrapper:hover),
.login-input :deep(.el-input__wrapper.is-focus) {
  box-shadow: none;
}

.login-input :deep(.el-input__wrapper.is-focus) {
  border-bottom-color: #ffffff;
}

.login-input :deep(.el-input__inner) {
  color: #ffffff;
  font-size: 16px;
}

.login-btn-item {
  margin-top: 40px;
  margin-bottom: 0;
}

.login-btn {
  width: 100%;
  height: 44px;
  border: none;
  border-radius: 8px;
  background: linear-gradient(135deg, #2b7a8a, #3aa67a);
  color: #ffffff;
  font-size: 16px;
  font-weight: 600;
  transition: filter 0.2s ease;
}

.login-btn:hover {
  filter: brightness(0.9);
}
</style>
