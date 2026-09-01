<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  Odometer,
  User,
  OfficeBuilding,
  FirstAidKit,
  Calendar,
  Tickets,
  List,
  UserFilled,
  SwitchButton,
} from '@element-plus/icons-vue'
import { useAuthStore } from '../store/auth'
import { adminLogout } from '../api/auth'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()

const menus = [
  { path: '/dashboard', title: '工作台', icon: Odometer },
  { path: '/users', title: '用户管理', icon: User },
  { path: '/departments', title: '科室管理', icon: OfficeBuilding },
  { path: '/doctors', title: '医生管理', icon: FirstAidKit },
  { path: '/schedule-rules', title: '排班管理', icon: Calendar },
  { path: '/levels', title: '挂号级别', icon: Tickets },
  { path: '/orders', title: '挂号记录', icon: List },
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
      <el-menu :default-active="activeMenu" router background-color="transparent" text-color="#d5e4e8" active-text-color="#ffffff">
        <el-menu-item v-for="menu in menus" :key="menu.path" :index="menu.path">
          <el-icon class="admin-menu-icon"><component :is="menu.icon" /></el-icon>
          <span>{{ menu.title }}</span>
        </el-menu-item>
      </el-menu>
    </el-aside>
    <el-container>
      <el-header class="admin-header">
        <span class="admin-page-title">{{ route.meta.title }}</span>
        <div class="admin-header-right">
          <el-avatar :size="32" class="admin-avatar">
            <el-icon><UserFilled /></el-icon>
          </el-avatar>
          <span class="admin-nickname">{{ authStore.user?.nickname || '管理员' }}</span>
          <el-button link class="admin-logout" @click="handleLogout">
            <el-icon class="admin-logout-icon"><SwitchButton /></el-icon>
            退出登录
          </el-button>
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
  background: linear-gradient(180deg, #2b7a8a 0%, #1f5b66 100%);
  overflow: hidden;
}

.admin-aside :deep(.el-menu) {
  border-right: none;
  padding: 8px;
}

.admin-aside :deep(.el-menu-item) {
  color: #d5e4e8;
  height: 46px;
  line-height: 46px;
  margin: 4px 0;
  border-radius: 8px;
  transition: all 0.2s ease;
}

.admin-aside :deep(.el-menu-item:hover) {
  background-color: rgba(255, 255, 255, 0.12);
  color: #ffffff;
}

.admin-aside :deep(.el-menu-item.is-active) {
  background-color: #3aa67a;
  color: #ffffff;
  box-shadow: 0 4px 10px rgba(58, 166, 122, 0.35);
}

.admin-menu-icon {
  margin-right: 10px;
  font-size: 18px;
}

.admin-logo {
  color: #fff;
  text-align: center;
  line-height: 60px;
  font-size: 17px;
  font-weight: 600;
  letter-spacing: 1px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.15);
}

.admin-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: #fff;
  border-bottom: 1px solid #e3ede9;
  padding: 0 24px;
  height: 60px;
  box-shadow: 0 1px 4px rgba(26, 43, 44, 0.04);
}

.admin-page-title {
  font-size: 17px;
  font-weight: 600;
  color: #1a2b2c;
}

.admin-header-right {
  display: flex;
  align-items: center;
  gap: 10px;
}

.admin-avatar {
  background-color: #2b7a8a;
  color: #fff;
}

.admin-nickname {
  color: #2e4041;
  font-size: 14px;
}

.admin-logout {
  color: #5c6f71;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  margin-left: 4px;
}

.admin-logout:hover {
  color: #2b7a8a;
}

.admin-logout-icon {
  font-size: 16px;
}

.admin-main {
  background: #f0f7f4;
  padding: 20px;
}
</style>
