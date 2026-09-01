<script setup>
import { onMounted, onBeforeUnmount, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import {
  User,
  OfficeBuilding,
  FirstAidKit,
  Tickets,
  Grid,
  UserFilled,
  Calendar,
  PriceTag,
  Document,
  Plus,
} from '@element-plus/icons-vue'
import * as echarts from 'echarts'
import { userApi, departmentApi, doctorApi, orderApi } from '../api/admin'

const router = useRouter()

const stats = reactive({
  userCount: '-',
  departmentCount: '-',
  doctorCount: '-',
  todayOrderCount: '-',
})

const statCards = [
  { key: 'userCount', title: '用户数', icon: User, color: '#2b7a8a' },
  { key: 'departmentCount', title: '科室数', icon: OfficeBuilding, color: '#3aa67a' },
  { key: 'doctorCount', title: '医生数', icon: FirstAidKit, color: '#2b7a8a' },
  { key: 'todayOrderCount', title: '今日预约数', icon: Tickets, color: '#3aa67a' },
]

const quickLinks = [
  { title: '用户管理', path: '/users', icon: User, color: '#5B8DB8' },
  { title: '科室管理', path: '/departments', icon: Grid, color: '#17A2B8' },
  { title: '医生管理', path: '/doctors', icon: UserFilled, color: '#3AA67A' },
  { title: '排班管理', path: '/schedule-rules', icon: Calendar, color: '#E6A23C' },
  { title: '挂号级别', path: '/levels', icon: PriceTag, color: '#9B6BB8' },
  { title: '挂号记录', path: '/orders', icon: Document, color: '#D06B6B' },
]

const trendData = ref([])
const top5Data = ref([])
const recentAppointments = ref([])

const STATUS_LABELS = {
  PENDING_PAYMENT: '待支付',
  PAID: '已支付',
  COMPLETED: '已完成',
  CANCELLED: '已取消',
}

const STATUS_TAG = {
  PENDING_PAYMENT: 'warning',
  PAID: 'success',
  COMPLETED: 'info',
  CANCELLED: 'info',
}

function statusLabel(status) {
  return STATUS_LABELS[status] || status || '-'
}

const trendChartRef = ref(null)
const top5ChartRef = ref(null)
let trendChart = null
let top5Chart = null

async function loadStat(request, assign) {
  try {
    const data = await request({ page: 1, size: 1 })
    assign(data.total)
  } catch {
    // 对应后台接口尚未上线时静默降级，保留占位符
  }
}

async function loadTrend() {
  try {
    trendData.value = await orderApi.dailyTrend()
  } catch {
    trendData.value = []
  }
  renderTrendChart()
}

async function loadTop5() {
  try {
    top5Data.value = await orderApi.departmentTop()
  } catch {
    top5Data.value = []
  }
  renderTop5Chart()
}

async function loadRecent() {
  try {
    const data = await orderApi.list({ page: 1, size: 5 })
    recentAppointments.value = (data.records || []).map((rec) => ({
      patientName: rec.contactName || '-',
      department: rec.departmentName || '-',
      doctor: rec.doctorName || '-',
      time: `${rec.visitDate || ''} ${rec.startTime || ''}`.trim() || '-',
      status: statusLabel(rec.status),
      statusType: STATUS_TAG[rec.status],
    }))
  } catch {
    recentAppointments.value = []
  }
}

function renderTrendChart() {
  if (!trendChart) return
  trendChart.setOption({
    tooltip: { trigger: 'axis' },
    grid: { left: '3%', right: '4%', bottom: '3%', top: '12%', containLabel: true },
    xAxis: {
      type: 'category',
      boundaryGap: false,
      data: trendData.value.map((d) => d.date),
      axisLine: { lineStyle: { color: '#d6e3df' } },
      axisLabel: { color: '#5c6f71' },
    },
    yAxis: {
      type: 'value',
      minInterval: 1,
      splitLine: { lineStyle: { color: '#edf4f1' } },
      axisLabel: { color: '#5c6f71' },
    },
    series: [
      {
        name: '预约量',
        type: 'line',
        smooth: true,
        data: trendData.value.map((d) => d.count),
        symbol: 'circle',
        symbolSize: 8,
        itemStyle: { color: '#2b7a8a' },
        lineStyle: { color: '#2b7a8a', width: 3 },
        areaStyle: {
          color: {
            type: 'linear',
            x: 0,
            y: 0,
            x2: 0,
            y2: 1,
            colorStops: [
              { offset: 0, color: 'rgba(43, 122, 138, 0.25)' },
              { offset: 1, color: 'rgba(43, 122, 138, 0)' },
            ],
          },
        },
      },
    ],
  })
}

function renderTop5Chart() {
  if (!top5Chart) return
  // 升序排列：水平条形图第一个数据在底部，最大值自然显示在最上方
  const sorted = [...top5Data.value].sort((a, b) => a.count - b.count)
  top5Chart.setOption({
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
    grid: { left: '3%', right: '10%', bottom: '3%', top: '8%', containLabel: true },
    xAxis: {
      type: 'value',
      minInterval: 1,
      splitLine: { lineStyle: { color: '#edf4f1' } },
      axisLabel: { color: '#5c6f71' },
    },
    yAxis: {
      type: 'category',
      data: sorted.map((d) => d.name),
      axisLabel: { color: '#5c6f71' },
      axisLine: { show: false },
      axisTick: { show: false },
    },
    series: [
      {
        name: '预约量',
        type: 'bar',
        data: sorted.map((d) => d.count),
        barWidth: 16,
        itemStyle: {
          color: {
            type: 'linear',
            x: 0,
            y: 0,
            x2: 1,
            y2: 0,
            colorStops: [
              { offset: 0, color: '#3aa67a' },
              { offset: 1, color: '#2b7a8a' },
            ],
          },
          borderRadius: [0, 8, 8, 0],
        },
        label: { show: true, position: 'right', color: '#5c6f71' },
      },
    ],
  })
}

function handleResize() {
  trendChart?.resize()
  top5Chart?.resize()
}

onMounted(() => {
  loadStat(userApi.list, (total) => (stats.userCount = total))
  loadStat(departmentApi.list, (total) => (stats.departmentCount = total))
  loadStat(doctorApi.list, (total) => (stats.doctorCount = total))
  loadStat(
    (params) => orderApi.list({ ...params, visitDate: new Date().toISOString().slice(0, 10) }),
    (total) => (stats.todayOrderCount = total)
  )

  trendChart = echarts.init(trendChartRef.value)
  top5Chart = echarts.init(top5ChartRef.value)

  loadTrend()
  loadTop5()
  loadRecent()

  window.addEventListener('resize', handleResize)
})

onBeforeUnmount(() => {
  window.removeEventListener('resize', handleResize)
  trendChart?.dispose()
  top5Chart?.dispose()
})
</script>

<template>
  <div class="dashboard">
    <el-row :gutter="16">
      <el-col v-for="item in statCards" :key="item.key" :span="6">
        <el-card class="stat-card">
          <div class="stat-icon" :style="{ background: item.color }">
            <el-icon :size="22"><component :is="item.icon" /></el-icon>
          </div>
          <div class="stat-body">
            <div class="stat-title">{{ item.title }}</div>
            <div class="stat-value">{{ stats[item.key] }}</div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="16" class="dashboard-row">
      <el-col :span="24">
        <el-card header="快捷入口">
          <div class="quick-links">
            <div
              v-for="link in quickLinks"
              :key="link.path"
              class="quick-card"
              @click="router.push(link.path)"
            >
              <el-icon :size="44" :color="link.color"><component :is="link.icon" /></el-icon>
              <span class="quick-card-label">{{ link.title }}</span>
            </div>
            <div class="quick-card quick-card-placeholder">
              <el-icon :size="44" color="#A0B8C8"><Plus /></el-icon>
              <span class="quick-card-label quick-card-placeholder-text">敬请期待</span>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="16" class="dashboard-row">
      <el-col :span="15">
        <el-card header="预约趋势（近 7 天）">
          <div ref="trendChartRef" class="chart"></div>
        </el-card>
      </el-col>
      <el-col :span="9">
        <el-card header="科室预约 TOP5">
          <div ref="top5ChartRef" class="chart"></div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="16" class="dashboard-row">
      <el-col :span="24">
        <el-card header="最近预约">
          <el-table :data="recentAppointments" stripe>
            <el-table-column type="index" label="序号" width="60" align="center" />
            <el-table-column prop="patientName" label="患者姓名" width="120" />
            <el-table-column prop="department" label="科室" width="140" />
            <el-table-column prop="doctor" label="医生" width="140" />
            <el-table-column prop="time" label="预约时间" min-width="180" />
            <el-table-column label="状态" width="120" align="center">
              <template #default="{ row }">
                <el-tag :type="row.statusType">{{ row.status }}</el-tag>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<style scoped>
.stat-card :deep(.el-card__body) {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 20px;
}

.stat-icon {
  width: 52px;
  height: 52px;
  border-radius: 12px;
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.stat-body {
  min-width: 0;
}

.stat-title {
  color: #5c6f71;
  font-size: 14px;
  font-weight: 400;
}

.stat-value {
  font-size: 28px;
  font-weight: 700;
  margin-top: 4px;
  color: #1a2b2c;
}

.dashboard-row {
  margin-top: 16px;
}

.chart {
  height: 300px;
  width: 100%;
}

.quick-links {
  display: flex;
  flex-wrap: wrap;
  justify-content: flex-start;
  gap: 20px;
}

.quick-card {
  width: 120px;
  height: 120px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 12px;
  background: #f8fafc;
  border: 1px solid #e3ede9;
  border-radius: 12px;
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(26, 43, 44, 0.04);
  transition: all 0.2s ease;
}

.quick-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 20px rgba(26, 43, 44, 0.12);
}

.quick-card-label {
  font-size: 14px;
  color: #1a2b2c;
}

.quick-card-placeholder {
  background: #e8ecf1;
  border: 1px dashed #cbd5dd;
  cursor: default;
  box-shadow: none;
}

.quick-card-placeholder:hover {
  transform: none;
  box-shadow: none;
}

.quick-card-placeholder-text {
  color: #a0b8c8;
  font-size: 12px;
}
</style>
