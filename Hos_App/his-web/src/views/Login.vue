<script setup>
import { reactive, ref, onMounted, onBeforeUnmount } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { User, Lock } from '@element-plus/icons-vue'
import { adminLogin } from '../api/auth'
import { useAuthStore } from '../store/auth'
import bg1 from '../assets/login-bg-1.jpg'
import bg2 from '../assets/login-bg-2.jpg'
import bg3 from '../assets/login-bg-3.jpg'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

const formRef = ref()
const loading = ref(false)

const bgImages = [bg1, bg2, bg3]
const current = ref(0)
let timer = null

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

onMounted(() => {
  timer = setInterval(() => {
    current.value = (current.value + 1) % bgImages.length
  }, 5000)
})

onBeforeUnmount(() => {
  if (timer) clearInterval(timer)
})
</script>

<template>
  <div class="login-page">
    <div class="bg-carousel">
      <div
        v-for="(img, i) in bgImages"
        :key="img"
        class="bg-slide"
        :class="{ active: i === current }"
        :style="{ backgroundImage: `url(${img})` }"
      ></div>
    </div>
    <div class="bg-overlay"></div>

    <div class="login-box">
      <div class="login-accent"></div>
      <div class="login-header">
        <h2 class="login-title">东软云医院挂号预约系统</h2>
        <p class="login-subtitle">管理员登录</p>
      </div>

      <el-form ref="formRef" :model="form" :rules="rules" @keyup.enter="handleSubmit">
        <el-form-item prop="username">
          <el-input v-model="form.username" placeholder="管理员账号">
            <template #prefix><el-icon><User /></el-icon></template>
          </el-input>
        </el-form-item>
        <el-form-item prop="password">
          <el-input v-model="form.password" type="password" placeholder="密码" show-password>
            <template #prefix><el-icon><Lock /></el-icon></template>
          </el-input>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" class="login-btn" :loading="loading" @click="handleSubmit">
            登 录
          </el-button>
        </el-form-item>
      </el-form>

      <p class="login-copyright">© 2026 东软云医院</p>
    </div>
  </div>
</template>

<style scoped>
.login-page {
  position: relative;
  height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.bg-carousel,
.bg-slide {
  position: absolute;
  inset: 0;
}

.bg-slide {
  background-size: cover;
  background-position: center;
  opacity: 0;
  transition: opacity 1.2s ease-in-out;
  will-change: opacity;
}

.bg-slide.active {
  opacity: 1;
}

.bg-overlay {
  position: absolute;
  inset: 0;
  background: rgba(0, 0, 0, 0.3);
  z-index: 1;
}

.login-box {
  position: relative;
  z-index: 2;
  width: 420px;
  box-sizing: border-box;
  padding: 48px;
  border-radius: 20px;
  background: rgba(255, 255, 255, 0.72);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.55);
  box-shadow: 0 25px 60px rgba(0, 0, 0, 0.25);
}

.login-accent {
  width: 40px;
  height: 4px;
  margin: 0 auto 28px;
  border-radius: 2px;
  background: linear-gradient(90deg, #2b7a8a, #3aa67a);
}

.login-header {
  text-align: center;
  margin-bottom: 28px;
}

.login-title {
  font-size: 24px;
  font-weight: 600;
  color: #1a2b2c;
}

.login-subtitle {
  margin: 8px 0 0;
  font-size: 14px;
  color: #5c6f71;
}

.login-box :deep(.el-input) {
  --el-input-height: 44px;
}

.login-box :deep(.el-input__wrapper) {
  border-radius: 10px;
  background: rgba(255, 255, 255, 0.9);
  box-shadow: 0 0 0 1px #e0e7ef inset;
  transition: box-shadow 0.2s ease;
}

.login-box :deep(.el-input__wrapper:hover) {
  box-shadow: 0 0 0 1px #c5d2dc inset;
}

.login-box :deep(.el-input__wrapper.is-focus) {
  box-shadow: 0 0 0 1px #2b7a8a inset, 0 0 10px rgba(43, 122, 138, 0.18);
}

.login-btn {
  width: 100%;
  height: 44px;
  border-radius: 10px;
  border: none;
  background-color: #2b7a8a;
  font-size: 16px;
  letter-spacing: 4px;
  transition: background-color 0.2s ease, transform 0.1s ease;
}

.login-btn:hover {
  background-color: #1f5f6f;
}

.login-btn:active {
  background-color: #1f5f6f;
  transform: translateY(2px);
}

.login-copyright {
  margin: 20px 0 0;
  text-align: center;
  font-size: 12px;
  color: #a0b8c8;
}
</style>
