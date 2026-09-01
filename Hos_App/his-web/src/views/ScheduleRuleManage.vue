<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search, Plus, Edit, Delete, Refresh } from '@element-plus/icons-vue'
import { scheduleRuleApi } from '../api/admin'

const WEEKDAYS = [
  { label: '周一', key: 1 },
  { label: '周二', key: 2 },
  { label: '周三', key: 4 },
  { label: '周四', key: 8 },
  { label: '周五', key: 16 },
  { label: '周六', key: 32 },
  { label: '周日', key: 64 },
]

const loading = ref(false)
const tableData = ref([])
const total = ref(0)

const query = reactive({
  ruleName: '',
  page: 1,
  size: 10,
})

const dialogVisible = ref(false)
const dialogMode = ref('create')
const formRef = ref()

function createGrid() {
  const g = {}
  WEEKDAYS.forEach((d) => { g[d.key] = { morning: false, afternoon: false } })
  return g
}

const form = reactive({
  id: null,
  levelId: null,
  ruleName: '',
  scheduleGrid: createGrid(),
  effectiveStart: '',
  effectiveEnd: '',
})

const rules = {
  ruleName: [{ required: true, message: '请输入排班说明', trigger: 'blur' }],
  effectiveStart: [{ required: true, message: '请选择生效开始日期', trigger: 'change' }],
}

const weekdayMask = computed(() => {
  let mask = 0
  WEEKDAYS.forEach((d) => {
    const cell = form.scheduleGrid[d.key]
    if (cell.morning || cell.afternoon) mask += d.key
  })
  return mask
})

const hasAnySelection = computed(() => {
  return WEEKDAYS.some((d) => form.scheduleGrid[d.key].morning || form.scheduleGrid[d.key].afternoon)
})

const period = computed(() => {
  let hasMorning = false
  let hasAfternoon = false
  WEEKDAYS.forEach((d) => {
    const cell = form.scheduleGrid[d.key]
    if (cell.morning) hasMorning = true
    if (cell.afternoon) hasAfternoon = true
  })
  if (hasMorning && hasAfternoon) return 'FULL'
  if (hasMorning) return 'MORNING'
  if (hasAfternoon) return 'AFTERNOON'
  return 'MORNING'
})

const ruleCode = computed(() => {
  let sb = ''
  WEEKDAYS.forEach((d) => {
    const cell = form.scheduleGrid[d.key]
    sb += cell.morning ? '1' : '0'
    sb += cell.afternoon ? '1' : '0'
  })
  return sb
})

const overviewPreview = computed(() => {
  const labels = []
  WEEKDAYS.forEach((d) => {
    const cell = form.scheduleGrid[d.key]
    if (cell.morning) labels.push(d.label + '上午')
    if (cell.afternoon) labels.push(d.label + '下午')
  })
  return labels
})

function weekdayLabel(mask) {
  return WEEKDAYS.filter((d) => (mask & d.key) === d.key).map((d) => d.label).join('、') || '-'
}

function periodLabel(p) {
  return { MORNING: '上午', AFTERNOON: '下午', FULL: '全天', EVENING: '晚上' }[p] || p
}

async function loadList() {
  loading.value = true
  try {
    const data = await scheduleRuleApi.list(query)
    tableData.value = data.records
    total.value = data.total
  } finally {
    loading.value = false
  }
}

function handleSearch() {
  query.page = 1
  loadList()
}

function handleReset() {
  query.ruleName = ''
  query.page = 1
  loadList()
}

function handleSizeChange() {
  query.page = 1
  loadList()
}

function openCreate() {
  dialogMode.value = 'create'
  Object.assign(form, {
    id: null,
    levelId: null,
    ruleName: '',
    scheduleGrid: createGrid(),
    effectiveStart: '',
    effectiveEnd: '',
  })
  dialogVisible.value = true
}

function openEdit(row) {
  dialogMode.value = 'edit'
  const grid = createGrid()
  const periodCodeMap = { MORNING: { morning: true, afternoon: false }, AFTERNOON: { morning: false, afternoon: true }, FULL: { morning: true, afternoon: true } }
  const cell = periodCodeMap[row.period] || { morning: false, afternoon: false }
  WEEKDAYS.forEach((d) => {
    if ((row.weekdayMask & d.key) === d.key) {
      grid[d.key] = { ...cell }
    }
  })
  Object.assign(form, {
    id: row.id,
    levelId: row.levelId,
    ruleName: row.ruleName,
    scheduleGrid: grid,
    effectiveStart: row.effectiveStart,
    effectiveEnd: row.effectiveEnd,
  })
  dialogVisible.value = true
}

async function handleSubmit() {
  await formRef.value.validate()
  if (!hasAnySelection.value) {
    ElMessage.warning('请至少选择一个排班时段')
    return
  }
  const payload = {
    id: form.id,
    ruleName: form.ruleName,
    weekdayMask: weekdayMask.value,
    period: period.value,
    effectiveStart: form.effectiveStart,
    effectiveEnd: form.effectiveEnd,
  }
  if (dialogMode.value === 'create') {
    await scheduleRuleApi.create(payload)
  } else {
    await scheduleRuleApi.update(payload.id, payload)
  }
  ElMessage.success('保存成功')
  dialogVisible.value = false
  loadList()
}

async function handleToggleStatus(row) {
  const action = row.enabled === 1 ? '停用' : '启用'
  const nextEnabled = row.enabled === 1 ? 0 : 1
  try {
    await ElMessageBox.confirm(`确定要${action}「${row.ruleName}」吗？`, `确认${action}`, { type: 'warning' })
  } catch {
    return
  }
  await scheduleRuleApi.toggleStatus(row.id, nextEnabled)
  ElMessage.success('操作成功')
  loadList()
}

async function handleDelete(row) {
  await ElMessageBox.confirm(`确认删除排班规则「${row.ruleName}」？`, '提示', { type: 'warning' })
  await scheduleRuleApi.remove(row.id)
  ElMessage.success('删除成功')
  loadList()
}

onMounted(() => {
  loadList()
})
</script>

<template>
  <div>
    <el-card class="filter-card" shadow="never">
      <el-form :inline="true" :model="query" @submit.prevent>
        <el-form-item label="排班说明">
          <el-input v-model="query.ruleName" placeholder="排班说明关键字" clearable @keyup.enter="handleSearch" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :icon="Search" @click="handleSearch">查询</el-button>
          <el-button :icon="Refresh" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card class="table-card" shadow="never">
      <div class="toolbar">
        <span class="toolbar-title">排班规则列表</span>
        <el-button type="primary" :icon="Plus" @click="openCreate">新增排班规则</el-button>
      </div>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column type="index" label="序号" width="60" align="center" :index="(index) => (query.page - 1) * query.size + index + 1" />
        <el-table-column prop="ruleName" label="排班说明" min-width="180" show-overflow-tooltip />
        <el-table-column label="排班概览" min-width="280">
          <template #default="{ row }">
            <div class="overview-tags">
              <el-tag v-for="(item, idx) in row.scheduleOverview" :key="idx" size="small" class="overview-tag">{{ item }}</el-tag>
              <span v-if="!row.scheduleOverview?.length" class="empty-tip">-</span>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="ruleCode" label="规则串" width="160" />
        <el-table-column prop="effectiveStart" label="生效开始" width="110" />
        <el-table-column prop="effectiveEnd" label="生效结束" width="110" />
        <el-table-column label="状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="row.enabled === 1 ? 'success' : 'info'">{{ row.enabled === 1 ? '已启用' : '已停用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" align="center">
          <template #default="{ row }">
            <el-button link type="primary" :icon="Edit" @click="openEdit(row)">编辑</el-button>
            <el-button link type="warning" @click="handleToggleStatus(row)">
              {{ row.enabled === 1 ? '停用' : '启用' }}
            </el-button>
            <el-button link type="danger" :icon="Delete" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination-wrap">
        <el-pagination
          v-model:current-page="query.page"
          v-model:page-size="query.size"
          :total="total"
          :page-sizes="[10, 20, 50, 100]"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="loadList"
        />
      </div>
    </el-card>

    <el-dialog v-model="dialogVisible" :title="dialogMode === 'create' ? '新增排班规则' : '编辑排班规则'" width="520px" align-center class="schedule-rule-dialog">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="排班说明" prop="ruleName">
          <el-input v-model="form.ruleName" placeholder="如：周一三五上午专家号" />
        </el-form-item>
        <el-form-item label="排班设置" required>
          <div class="schedule-grid">
            <div class="grid-header">
              <span class="grid-day-col"></span>
              <span class="grid-col">上午</span>
              <span class="grid-col">下午</span>
            </div>
            <div v-for="d in WEEKDAYS" :key="d.key" class="grid-row">
              <span class="grid-day-col">{{ d.label }}</span>
              <el-checkbox v-model="form.scheduleGrid[d.key].morning" class="grid-col" />
              <el-checkbox v-model="form.scheduleGrid[d.key].afternoon" class="grid-col" />
            </div>
          </div>
        </el-form-item>
        <el-form-item label="生效开始" prop="effectiveStart">
          <el-date-picker v-model="form.effectiveStart" type="date" value-format="YYYY-MM-DD" style="width: 100%" />
        </el-form-item>
        <el-form-item label="生效结束">
          <el-date-picker v-model="form.effectiveEnd" type="date" value-format="YYYY-MM-DD" style="width: 100%" placeholder="留空表示长期有效" />
        </el-form-item>
        <el-form-item label="预览">
          <div class="preview-box">
            <div class="preview-overview">
              <el-tag v-for="(item, idx) in overviewPreview" :key="idx" size="small">{{ item }}</el-tag>
              <span v-if="!overviewPreview.length" class="empty-tip">未选择</span>
            </div>
            <div class="rule-code">规则串：{{ ruleCode }}</div>
          </div>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style>
.schedule-rule-dialog .el-dialog {
  margin: 0 auto;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
}
.schedule-rule-dialog .el-dialog__body {
  overflow-y: auto;
  flex: 1;
}
</style>

<style scoped>
.schedule-grid {
  border: 1px solid #ebeef5;
  border-radius: 6px;
  padding: 8px 12px;
  width: fit-content;
}

.grid-header,
.grid-row {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 4px 0;
}

.grid-header {
  color: #909399;
  font-size: 13px;
}

.grid-day-col {
  width: 48px;
  text-align: right;
  font-weight: 500;
  color: #303133;
}

.grid-col {
  width: 56px;
  justify-content: center;
}

.preview-box {
  background: #f0f7f4;
  border-radius: 6px;
  padding: 8px 12px;
  color: #2e4041;
  font-size: 13px;
}

.rule-code {
  margin-top: 4px;
  color: #5c6f71;
}

.preview-overview {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
}

.overview-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  align-items: center;
}

.overview-tag {
  margin: 0;
}

.empty-tip {
  color: #c0c4cc;
}
</style>
