<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { scheduleRuleApi, doctorApi } from '../api/admin'

const WEEKDAYS = [
  { label: '周一', bit: 1 },
  { label: '周二', bit: 2 },
  { label: '周三', bit: 4 },
  { label: '周四', bit: 8 },
  { label: '周五', bit: 16 },
  { label: '周六', bit: 32 },
  { label: '周日', bit: 64 },
]

const PERIODS = [
  { label: '上午', value: 'MORNING' },
  { label: '下午', value: 'AFTERNOON' },
  { label: '晚上', value: 'EVENING' },
]

const loading = ref(false)
const tableData = ref([])
const total = ref(0)
const doctorOptions = ref([])

const query = reactive({
  page: 1,
  size: 10,
})

const dialogVisible = ref(false)
const dialogMode = ref('create')
const formRef = ref()
const form = reactive({
  id: null,
  doctorId: null,
  levelId: null,
  ruleName: '',
  weekdays: [],
  period: 'MORNING',
  slots: [{ start: '08:00', end: '08:30', quota: 10 }],
  effectiveStart: '',
  effectiveEnd: '',
})

const rules = {
  ruleName: [{ required: true, message: '请输入排班说明', trigger: 'blur' }],
  doctorId: [{ required: true, message: '请选择医生', trigger: 'change' }],
  effectiveStart: [{ required: true, message: '请选择生效开始日期', trigger: 'change' }],
}

const weekdayMask = computed(() => form.weekdays.reduce((sum, bit) => sum + bit, 0))

const humanPreview = computed(() => {
  const names = WEEKDAYS.filter((item) => form.weekdays.includes(item.bit)).map((item) => item.label).join('、')
  const periodLabel = PERIODS.find((item) => item.value === form.period)?.label || ''
  return `${names || '未选择星期'} ${periodLabel} 共 ${form.slots.length} 个时段`
})

const ruleCode = computed(() => `${weekdayMask.value}-${form.period}`)

function weekdayLabel(mask) {
  return WEEKDAYS.filter((item) => (mask & item.bit) === item.bit).map((item) => item.label).join('、') || '-'
}

function periodLabel(period) {
  return PERIODS.find((item) => item.value === period)?.label || period
}

function addSlot() {
  form.slots.push({ start: '', end: '', quota: 10 })
}

function removeSlot(index) {
  form.slots.splice(index, 1)
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

async function loadDoctorOptions() {
  try {
    const data = await doctorApi.list({ page: 1, size: 200 })
    doctorOptions.value = data.records
  } catch {
    doctorOptions.value = []
  }
}

function openCreate() {
  dialogMode.value = 'create'
  Object.assign(form, {
    id: null,
    doctorId: null,
    levelId: null,
    ruleName: '',
    weekdays: [],
    period: 'MORNING',
    slots: [{ start: '08:00', end: '08:30', quota: 10 }],
    effectiveStart: '',
    effectiveEnd: '',
  })
  dialogVisible.value = true
}

function openEdit(row) {
  dialogMode.value = 'edit'
  Object.assign(form, {
    ...row,
    weekdays: WEEKDAYS.filter((item) => (row.weekdayMask & item.bit) === item.bit).map((item) => item.bit),
    slots: row.slotsJson ? JSON.parse(row.slotsJson) : [],
  })
  dialogVisible.value = true
}

async function handleSubmit() {
  await formRef.value.validate()
  const payload = {
    ...form,
    weekdayMask: weekdayMask.value,
    slotsJson: JSON.stringify(form.slots),
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
  const nextEnabled = row.enabled === 1 ? 0 : 1
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
  loadDoctorOptions()
})
</script>

<template>
  <div>
    <el-form :inline="true">
      <el-form-item>
        <el-button type="success" @click="openCreate">新增排班规则</el-button>
      </el-form-item>
    </el-form>

    <el-table v-loading="loading" :data="tableData" border>
      <el-table-column prop="ruleName" label="排班说明" width="160" />
      <el-table-column prop="doctorId" label="医生ID" width="90" />
      <el-table-column label="星期" width="160">
        <template #default="{ row }">{{ weekdayLabel(row.weekdayMask) }}</template>
      </el-table-column>
      <el-table-column label="时段" width="90">
        <template #default="{ row }">{{ periodLabel(row.period) }}</template>
      </el-table-column>
      <el-table-column prop="effectiveStart" label="生效开始" width="120" />
      <el-table-column prop="effectiveEnd" label="生效结束" width="120" />
      <el-table-column label="状态" width="100">
        <template #default="{ row }">
          <el-tag :type="row.enabled === 1 ? 'success' : 'info'">{{ row.enabled === 1 ? '已启用' : '已停用' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="220">
        <template #default="{ row }">
          <el-button link type="primary" @click="openEdit(row)">编辑</el-button>
          <el-button link type="warning" @click="handleToggleStatus(row)">
            {{ row.enabled === 1 ? '停用' : '启用' }}
          </el-button>
          <el-button link type="danger" @click="handleDelete(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination
      class="pagination"
      v-model:current-page="query.page"
      v-model:page-size="query.size"
      :total="total"
      layout="total, prev, pager, next"
      @current-change="loadList"
    />

    <el-dialog v-model="dialogVisible" :title="dialogMode === 'create' ? '新增排班规则' : '编辑排班规则'" width="560px">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="排班说明" prop="ruleName">
          <el-input v-model="form.ruleName" placeholder="如：周一三五上午专家号" />
        </el-form-item>
        <el-form-item label="医生" prop="doctorId">
          <el-select v-model="form.doctorId" style="width: 100%">
            <el-option v-for="doctor in doctorOptions" :key="doctor.id" :label="doctor.name" :value="doctor.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="星期集合">
          <el-checkbox-group v-model="form.weekdays">
            <el-checkbox v-for="item in WEEKDAYS" :key="item.bit" :value="item.bit">{{ item.label }}</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
        <el-form-item label="上午/下午">
          <el-radio-group v-model="form.period">
            <el-radio v-for="item in PERIODS" :key="item.value" :value="item.value">{{ item.label }}</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="时段规则">
          <div v-for="(slot, index) in form.slots" :key="index" class="slot-row">
            <el-time-select v-model="slot.start" placeholder="开始" start="06:00" end="22:00" step="00:15" style="width: 120px" />
            <span class="slot-sep">至</span>
            <el-time-select v-model="slot.end" placeholder="结束" start="06:00" end="22:00" step="00:15" style="width: 120px" />
            <el-input-number v-model="slot.quota" :min="1" placeholder="限额" style="width: 100px" />
            <el-button link type="danger" @click="removeSlot(index)">删除</el-button>
          </div>
          <el-button link type="primary" @click="addSlot">+ 新增时段</el-button>
        </el-form-item>
        <el-form-item label="生效开始" prop="effectiveStart">
          <el-date-picker v-model="form.effectiveStart" type="date" value-format="YYYY-MM-DD" style="width: 100%" />
        </el-form-item>
        <el-form-item label="生效结束">
          <el-date-picker v-model="form.effectiveEnd" type="date" value-format="YYYY-MM-DD" style="width: 100%" placeholder="留空表示长期有效" />
        </el-form-item>
        <el-form-item label="预览">
          <div class="preview-box">
            <div>{{ humanPreview }}</div>
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

<style scoped>
.pagination {
  margin-top: 16px;
  justify-content: flex-end;
}

.slot-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 8px;
}

.slot-sep {
  color: #909399;
}

.preview-box {
  background: #f5f7fa;
  border-radius: 4px;
  padding: 8px 12px;
  color: #606266;
  font-size: 13px;
}

.rule-code {
  margin-top: 4px;
  color: #909399;
}
</style>
