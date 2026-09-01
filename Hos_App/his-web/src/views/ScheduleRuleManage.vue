<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Edit, Delete } from '@element-plus/icons-vue'
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

// 查询参数
const query = reactive({
  ruleName: '',
  page: 1,
  size: 10,
})

// 模拟数据，完全匹配第二张截图，无医生姓名职称
const mockScheduleList = [
  {
    id: 1,
    ruleName: '星期一三五上午',
    previewTags: ['周一上午', '周三上午', '周五上午'],
    ruleStr: '00100010001000',
    enabled: 1
  },
  {
    id: 2,
    ruleName: '星期一三五下午',
    previewTags: ['周一下午', '周三下午', '周五下午'],
    ruleStr: '00010001000100',
    enabled: 1
  },
  {
    id: 3,
    ruleName: '星期二四六上午',
    previewTags: ['周二上午', '周四上午', '周六上午'],
    ruleStr: '00001000100010',
    enabled: 1
  },
  {
    id: 4,
    ruleName: '星期二四六下午',
    previewTags: ['周二下午', '周四下午', '周六下午'],
    ruleStr: '00000100010001',
    enabled: 1
  },
  {
    id: 5,
    ruleName: '周六周日全天',
    previewTags: ['周日全天', '周六全天'],
    ruleStr: '11000000000011',
    enabled: 1
  }
]

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
  return `${names || '未选择星期'} ${periodLabel}`
})

const ruleCode = computed(() => `${weekdayMask.value}-${form.period}`)

function addSlot() {
  form.slots.push({ start: '', end: '', quota: 10 })
}

function removeSlot(index) {
  form.slots.splice(index, 1)
}

async function loadList() {
  loading.value = true
  try {
    // 模拟数据，对接后端注释下面，打开接口
    let filter = [...mockScheduleList]
    if (query.ruleName) {
      filter = filter.filter(item => item.ruleName.includes(query.ruleName))
    }
    tableData.value = filter
    total.value = filter.length

    // const data = await scheduleRuleApi.list(query)
    // tableData.value = data.records
    // total.value = data.total
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

// 查询
function handleSearch() {
  query.page = 1
  loadList()
}
// 重置
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
    weekdays: [],
    slots: [{ start: '08:00', end: '08:30', quota: 10 }],
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
  <div class="schedule-page">
    <el-card shadow="never">
      <!-- 查询区域 -->
      <el-form inline :model="query">
        <el-form-item label="排班说明">
          <el-input v-model="query.ruleName" placeholder="请输入说明" clearable style="width:240px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSearch">查询</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card shadow="never" style="margin-top:12px">
      <div class="table-header">
        <h3>排班规则列表</h3>
        <el-button type="primary" :icon="Plus" @click="openCreate">新增排班规则</el-button>
      </div>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column
          type="index"
          label="序号"
          width="60"
          align="center"
          :index="(idx) => (query.page - 1) * query.size + idx + 1"
        />
        <el-table-column prop="ruleName" label="排班说明" min-width="240" />
        <el-table-column label="排班概览" min-width="340">
          <template #default="{ row }">
            <el-tag
              v-for="tagText in row.previewTags"
              :key="tagText"
              size="small"
              effect="plain"
              style="margin:0 6px 4px 0"
            >
              {{ tagText }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="ruleStr" label="规则串" width="180" />
        <el-table-column label="生效标记" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="row.enabled ===1 ? 'success' : 'info'" effect="plain">
              {{ row.enabled === 1 ? '生效' : '停用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="260" align="center">
          <template #default="{ row }">
            <el-button link type="primary" :icon="Edit" @click="openEdit(row)">编辑</el-button>
            <el-button link type="warning" @click="handleToggleStatus(row)">停用</el-button>
            <el-button link type="danger" :icon="Delete" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination-wrap">
        <el-pagination
          v-model:current-page="query.page"
          v-model:page-size="query.size"
          :total="total"
          :page-sizes="[10,20,50,100]"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="loadList"
        />
      </div>
    </el-card>

    <!-- 新增编辑弹窗 -->
    <el-dialog
      v-model="dialogVisible"
      :title="dialogMode === 'create' ? '新增排班规则' : '编辑排班规则'"
      width="580px"
    >
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="排班说明" prop="ruleName">
          <el-input v-model="form.ruleName" placeholder="格式示例：星期一三五上午" />
        </el-form-item>
        <el-form-item label="医生" prop="doctorId">
          <el-select v-model="form.doctorId" style="width:100%">
            <el-option v-for="doc in doctorOptions" :key="doc.id" :label="doc.name" :value="doc.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="星期集合">
          <el-checkbox-group v-model="form.weekdays">
            <el-checkbox v-for="w in WEEKDAYS" :key="w.bit" :value="w.bit">{{w.label}}</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
        <el-form-item label="上午/下午">
          <el-radio-group v-model="form.period">
            <el-radio label="MORNING">上午</el-radio>
            <el-radio label="AFTERNOON">下午</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="时段规则">
          <div v-for="(slot, idx) in form.slots" :key="idx" class="slot-row">
            <el-time-select v-model="slot.start" start="06:00" end="22:00" step="00:15" style="width:120px" />
            <span class="sep">至</span>
            <el-time-select v-model="slot.end" start="06:00" end="22:00" step="00:15" style="width:120px" />
            <el-input-number v-model="slot.quota" :min="1" style="width:100px" />
            <el-button link type="danger" @click="removeSlot(idx)">删除</el-button>
          </div>
          <el-button link type="primary" @click="addSlot">+新增时段</el-button>
        </el-form-item>
        <el-form-item label="生效开始" prop="effectiveStart">
          <el-date-picker v-model="form.effectiveStart" type="date" value-format="YYYY‑MM‑DD" style="width:100%" />
        </el-form-item>
        <el-form-item label="生效结束">
          <el-date-picker v-model="form.effectiveEnd" type="date" value-format="YYYY‑MM‑DD" style="width:100%" placeholder="留空长期有效" />
        </el-form-item>
        <el-form-item label="预览">
          <div class="preview-box">
            <div>{{ humanPreview }}</div>
            <div>规则串：{{ ruleCode }}</div>
          </div>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible=false">取消</el-button>
        <el-button type="primary" @click="handleSubmit">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
.table-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom:14px;
}
.pagination-wrap {
  margin-top:16px;
  display:flex;
  justify-content:flex-end;
}
.slot-row {
  display:flex;
  gap:8px;
  align-items:center;
  margin-bottom:8px;
}
.sep {
  color:#999;
}
.preview-box {
  background-color:#f4f7f9;
  padding:8px 12px;
  border-radius:6px;
  font-size:13px;
}
</style>
