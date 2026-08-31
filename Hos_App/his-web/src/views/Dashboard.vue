<script setup>
import { onMounted, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { userApi, departmentApi, doctorApi, orderApi } from '../api/admin'

const router = useRouter()

const stats = reactive({
  userCount: '-',
  departmentCount: '-',
  doctorCount: '-',
  todayOrderCount: '-',
})

const quickLinks = [
  { title: '用户管理', path: '/users' },
  { title: '科室管理', path: '/departments' },
  { title: '医生管理', path: '/doctors' },
  { title: '排班管理', path: '/schedule-rules' },
  { title: '挂号级别', path: '/levels' },
  { title: '挂号记录', path: '/orders' },
]

const techStack = [
  { group: '服务端', detail: 'Spring Boot 3 / JDK 17 / MyBatis-Plus / MySQL 8' },
  { group: '管理端', detail: 'Vue 3 / Vite / Element Plus / Pinia / Axios' },
  { group: '移动端', detail: 'HarmonyOS / ArkTS / ArkUI' },
]

async function loadStat(request, assign) {
  try {
    const data = await request({ page: 1, size: 1 })
    assign(data.total)
  } catch {
    // 对应后台接口尚未上线时静默降级，保留占位符
  }
}

onMounted(() => {
  loadStat(userApi.list, (total) => (stats.userCount = total))
  loadStat(departmentApi.list, (total) => (stats.departmentCount = total))
  loadStat(doctorApi.list, (total) => (stats.doctorCount = total))
  loadStat(
    (params) => orderApi.list({ ...params, visitDate: new Date().toISOString().slice(0, 10) }),
    (total) => (stats.todayOrderCount = total)
  )
})
</script>

<template>
  <div class="dashboard">
    <el-row :gutter="16">
      <el-col :span="6">
        <el-card><div class="stat-title">用户数</div><div class="stat-value">{{ stats.userCount }}</div></el-card>
      </el-col>
      <el-col :span="6">
        <el-card><div class="stat-title">科室数</div><div class="stat-value">{{ stats.departmentCount }}</div></el-card>
      </el-col>
      <el-col :span="6">
        <el-card><div class="stat-title">医生数</div><div class="stat-value">{{ stats.doctorCount }}</div></el-card>
      </el-col>
      <el-col :span="6">
        <el-card><div class="stat-title">今日预约数</div><div class="stat-value">{{ stats.todayOrderCount }}</div></el-card>
      </el-col>
    </el-row>

    <el-row :gutter="16" class="dashboard-row">
      <el-col :span="12">
        <el-card header="快捷入口">
          <div class="quick-links">
            <el-button v-for="link in quickLinks" :key="link.path" @click="router.push(link.path)">
              {{ link.title }}
            </el-button>
          </div>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card header="系统 / 技术栈信息">
          <el-descriptions :column="1" border>
            <el-descriptions-item v-for="item in techStack" :key="item.group" :label="item.group">
              {{ item.detail }}
            </el-descriptions-item>
          </el-descriptions>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<style scoped>
.stat-title {
  color: #909399;
  font-size: 13px;
}

.stat-value {
  font-size: 28px;
  font-weight: 600;
  margin-top: 8px;
}

.dashboard-row {
  margin-top: 16px;
}

.quick-links {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
}
</style>
