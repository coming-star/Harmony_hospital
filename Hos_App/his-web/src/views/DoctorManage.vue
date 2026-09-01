<script setup>
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search, Plus, Edit, Delete, Refresh } from '@element-plus/icons-vue'
import { doctorApi, levelApi, scheduleRuleApi } from '../api/admin'
import request from '../api/request'

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
  { label: '全天', value: 'FULL' },
  { label: '晚上', value: 'EVENING' },
]

function weekdayLabel(mask) {
  return WEEKDAYS.filter((item) => (mask & item.bit) === item.bit).map((item) => item.label).join('、') || '-'
}

function periodLabel(period) {
  return PERIODS.find((item) => item.value === period)?.label || period
}

function levelName(levelId) {
  return levelOptions.value.find((item) => item.id === levelId)?.name || levelId
}

const loading = ref(false)
const tableData = ref([])
const total = ref(0)
const departmentOptions = ref([])
const levelOptions = ref([])
const scheduleRuleOptions = ref([])

const secondLevelByParent = computed(() => {
  const map = {}
  for (const first of departmentOptions.value) {
    map[first.id] = first.children || []
  }
  return map
})

const availableScheduleRules = computed(() => scheduleRuleOptions.value)

const query = reactive({
  name: '',
  departmentId: '',
  page: 1,
  size: 10,
})

const dialogVisible = ref(false)
const dialogMode = ref('create')
const formRef = ref()
const form = reactive({
  id: null,
  name: '',
  parentDepartmentId: null,
  departmentId: null,
  title: '',
  introduction: '',
  levelIds: [],
  scheduleRuleIds: [],
})

watch(() => form.parentDepartmentId, () => {
  form.departmentId = null
})

const rules = {
  name: [{ required: true, message: '请输入医生姓名', trigger: 'blur' }],
  departmentId: [{ required: true, message: '请选择所属科室', trigger: 'change' }],
}

async function loadList() {
  loading.value = true
  try {
    const data = await doctorApi.list(query)
    tableData.value = data.records
    total.value = data.total
  } finally {
    loading.value = false
  }
}

async function loadDepartmentOptions() {
  try {
    departmentOptions.value = await request.get('/api/departments/tree')
  } catch {
    departmentOptions.value = []
  }
}

async function loadLevelOptions() {
  try {
    const data = await levelApi.list({ page: 1, size: 100 })
    levelOptions.value = data.records
  } catch {
    levelOptions.value = []
  }
}

async function loadScheduleRuleOptions() {
  try {
    const data = await scheduleRuleApi.list({ page: 1, size: 200 })
    scheduleRuleOptions.value = data.records || []
  } catch {
    scheduleRuleOptions.value = []
  }
}

function handleSearch() {
  query.page = 1
  loadList()
}

function handleReset() {
  query.name = ''
  query.departmentId = ''
  query.page = 1
  loadList()
}

function handleSizeChange() {
  query.page = 1
  loadList()
}

function openCreate() {
  dialogMode.value = 'create'
  Object.assign(form, { id: null, name: '', parentDepartmentId: null, departmentId: null, title: '', introduction: '', levelIds: [], scheduleRuleIds: [] })
  dialogVisible.value = true
}

function openEdit(row) {
  dialogMode.value = 'edit'
  const parentId = findParentId(row.departmentId)
  Object.assign(form, {
    id: row.id,
    name: row.name,
    parentDepartmentId: parentId,
    departmentId: row.departmentId,
    title: row.title,
    introduction: row.introduction,
    levelIds: row.levelIds || [],
    scheduleRuleIds: (row.scheduleRules || []).map((r) => r.ruleId),
  })
  dialogVisible.value = true
}

function findParentId(deptId) {
  for (const first of departmentOptions.value) {
    if ((first.children || []).some((c) => c.id === deptId)) {
      return first.id
    }
  }
  return null
}

async function handleSubmit() {
  await formRef.value.validate()
  if (dialogMode.value === 'create') {
    await doctorApi.create(form)
  } else {
    await doctorApi.update(form.id, form)
  }
  ElMessage.success('保存成功')
  dialogVisible.value = false
  loadList()
}

async function handleToggleStatus(row) {
  const action = row.enabled === 1 ? '停用' : '启用'
  const nextEnabled = row.enabled === 1 ? 0 : 1
  try {
    await ElMessageBox.confirm(`确定要${action}「${row.name}」吗？`, `确认${action}`, { type: 'warning' })
  } catch {
    return
  }
  await doctorApi.toggleStatus(row.id, nextEnabled)
  ElMessage.success('操作成功')
  loadList()
}

async function handleDelete(row) {
  await ElMessageBox.confirm(`确认删除医生「${row.name}」？`, '提示', { type: 'warning' })
  await doctorApi.remove(row.id)
  ElMessage.success('删除成功')
  loadList()
}

onMounted(() => {
  loadList()
  loadDepartmentOptions()
  loadLevelOptions()
  loadScheduleRuleOptions()
})
</script>

<template>
  <div>
    <el-card class="filter-card" shadow="never">
      <el-form :inline="true" :model="query" @submit.prevent>
        <el-form-item label="姓名">
          <el-input v-model="query.name" placeholder="医生姓名" clearable @keyup.enter="handleSearch" />
        </el-form-item>
        <el-form-item label="一级科室">
          <el-select v-model="query.departmentId" placeholder="全部" clearable style="width: 160px" @change="handleSearch">
            <el-option v-for="dept in departmentOptions" :key="dept.id" :label="dept.name" :value="dept.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :icon="Search" @click="handleSearch">查询</el-button>
          <el-button :icon="Refresh" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card class="table-card" shadow="never">
      <div class="toolbar">
        <span class="toolbar-title">医生列表</span>
        <el-button type="primary" :icon="Plus" @click="openCreate">新增医生</el-button>
      </div>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column type="index" label="序号" width="60" align="center" :index="(index) => (query.page - 1) * query.size + index + 1" />
        <el-table-column prop="name" label="姓名" width="110" />
        <el-table-column prop="title" label="职称" width="130" />
        <el-table-column prop="departmentName" label="所属科室" width="120" />
        <el-table-column prop="introduction" label="简介" min-width="160" show-overflow-tooltip class-name="cell-left" />
        <el-table-column label="挂号级别" width="140">
          <template #default="{ row }">
            <el-tag
              v-for="levelId in row.levelIds"
              :key="levelId"
              size="small"
              style="margin: 0 4px 4px 0"
            >
              {{ levelName(levelId) }}
            </el-tag>
            <span v-if="!row.levelIds || row.levelIds.length === 0">-</span>
          </template>
        </el-table-column>
        <el-table-column label="排班规则" min-width="200">
          <template #default="{ row }">
            <el-tag
              v-for="(rule, index) in row.scheduleRules"
              :key="index"
              size="small"
              type="success"
              style="margin: 0 4px 4px 0"
            >
              {{ weekdayLabel(rule.weekdayMask) }} {{ periodLabel(rule.period) }}
            </el-tag>
            <span v-if="!row.scheduleRules || row.scheduleRules.length === 0">-</span>
          </template>
        </el-table-column>
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

    <el-dialog v-model="dialogVisible" :title="dialogMode === 'create' ? '新增医生' : '编辑医生'" width="480px">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="90px">
        <el-form-item label="姓名" prop="name">
          <el-input v-model="form.name" />
        </el-form-item>
        <el-form-item label="一级科室" prop="parentDepartmentId">
          <el-select v-model="form.parentDepartmentId" placeholder="请选择一级科室" style="width: 100%">
            <el-option v-for="dept in departmentOptions" :key="dept.id" :label="dept.name" :value="dept.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="二级科室" prop="departmentId">
          <el-select v-model="form.departmentId" placeholder="请选择二级科室" style="width: 100%" :disabled="!form.parentDepartmentId">
            <el-option v-for="dept in (secondLevelByParent[form.parentDepartmentId] || [])" :key="dept.id" :label="dept.name" :value="dept.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="职称">
          <el-input v-model="form.title" placeholder="如主任医师" />
        </el-form-item>
        <el-form-item label="挂号级别">
          <el-select v-model="form.levelIds" multiple style="width: 100%">
            <el-option v-for="level in levelOptions" :key="level.id" :label="level.name" :value="level.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="排班规则">
          <el-select v-model="form.scheduleRuleIds" multiple style="width: 100%" placeholder="可选">
            <el-option
              v-for="rule in availableScheduleRules"
              :key="rule.id"
              :label="rule.ruleName"
              :value="rule.id"
            >
              <span>{{ rule.ruleName }}</span>
              <span style="float: right; color: #999; font-size: 12px">
                {{ weekdayLabel(rule.weekdayMask) }} {{ periodLabel(rule.period) }}
              </span>
            </el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="简介">
          <el-input v-model="form.introduction" type="textarea" :rows="3" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>
