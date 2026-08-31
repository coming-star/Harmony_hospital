<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../store/auth'
import { adminLogout } from '../api/auth'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()

const menus = [
  { path: '/dashboard', title: '工作台' },
  { path: '/users', title: '用户管理' },
  { path: '/departments', title: '科室管理' },
  { path: '/doctors', title: '医生管理' },
  { path: '/schedule-rules', title: '排班管理' },
  { path: '/levels', title: '挂号级别' },
  { path: '/orders', title: '挂号记录' },
]

const activeMenu = computed(() => route.path)

async function handleLogout() {
  try {
    await adminLogout()
  } finally {
    authStore.logout()
    router.push('/login')
  }
}
</script>

<template>
  <el-container class="admin-layout">
    <el-aside width="200px" class="admin-aside">
      <div class="admin-logo">东软云医院后台</div>
      <el-menu :default-active="activeMenu" router background-color="#001529" text-color="#c8d4e0" active-text-color="#ffffff">
        <el-menu-item v-for="menu in menus" :key="menu.path" :index="menu.path">
          {{ menu.title }}
        </el-menu-item>
      </el-menu>
    </el-aside>
    <el-container>
      <el-header class="admin-header">
        <span>{{ route.meta.title }}</span>
        <div class="admin-header-right">
          <span class="admin-nickname">{{ authStore.user?.nickname }}</span>
          <el-button link @click="handleLogout">退出登录</el-button>
        </div>
      </el-header>
      <el-main class="admin-main">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<style scoped>
.admin-layout {
  height: 100vh;
}

.admin-aside {
  background-color: #001529;
  overflow: hidden;
}

.admin-logo {
  color: #fff;
  text-align: center;
  line-height: 60px;
  font-size: 16px;
  font-weight: 600;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.admin-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: #fff;
  border-bottom: 1px solid #e4e7ed;
  font-size: 16px;
  font-weight: 500;
}

.admin-header-right {
  display: flex;
  align-items: center;
  gap: 12px;
}

.admin-nickname {
  color: #606266;
}

.admin-main {
  background: #f5f7fa;
}
</style>
