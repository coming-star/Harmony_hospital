<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search, Plus, Edit, Delete, Refresh } from '@element-plus/icons-vue'
import { departmentApi } from '../api/admin'
import request from '../api/request'

const loading = ref(false)
const tableData = ref([])
const total = ref(0)
const parentOptions = ref([])
const firstLevelDepartments = ref([])

const query = reactive({
  name: '',
  parentId: null,
  page: 1,
  size: 10,
})

const dialogVisible = ref(false)
const dialogMode = ref('create')
const formRef = ref()
const form = reactive({
  id: null,
  code: '',
  name: '',
  departmentType: 'CLINICAL',
  parentId: 0,
  description: '',
  sortNo: 0,
})

const rules = {
  code: [{ required: true, message: '请输入科室编码', trigger: 'blur' }],
  name: [{ required: true, message: '请输入科室名称', trigger: 'blur' }],
}

async function loadList() {
  loading.value = true
  try {
    const data = await departmentApi.list(query)
    tableData.value = data.records
    total.value = data.total
  } finally {
    loading.value = false
  }
}

async function loadParentOptions() {
  try {
    parentOptions.value = await request.get('/api/departments/tree')
  } catch {
    parentOptions.value = []
  }
}

async function loadFirstLevelDepartments() {
  try {
    const tree = await request.get('/api/departments/tree')
    firstLevelDepartments.value = tree || []
  } catch {
    firstLevelDepartments.value = []
  }
}

function handleSearch() {
  query.page = 1
  loadList()
}

function handleReset() {
  query.name = ''
  query.parentId = null
  query.page = 1
  loadList()
}

function handleSizeChange() {
  query.page = 1
  loadList()
}

function openCreate() {
  dialogMode.value = 'create'
  Object.assign(form, { id: null, code: '', name: '', departmentType: 'CLINICAL', parentId: 0, description: '', sortNo: 0 })
  dialogVisible.value = true
}

function openEdit(row) {
  dialogMode.value = 'edit'
  Object.assign(form, { ...row })
  dialogVisible.value = true
}

async function handleSubmit() {
  await formRef.value.validate()
  if (dialogMode.value === 'create') {
    await departmentApi.create(form)
  } else {
    await departmentApi.update(form.id, form)
  }
  ElMessage.success('保存成功')
  dialogVisible.value = false
  loadList()
}

async function handleDelete(row) {
  await ElMessageBox.confirm(`确认删除科室「${row.name}」？被医生/排班引用时将无法删除。`, '提示', { type: 'warning' })
  await departmentApi.remove(row.id)
  ElMessage.success('删除成功')
  loadList()
}

async function handleToggleStatus(row) {
  const next = row.enabled === 1 ? 0 : 1
  const action = next === 1 ? '启用' : '停用'
  await ElMessageBox.confirm(`确认${action}科室「${row.name}」？`, '提示', { type: 'warning' })
  await departmentApi.toggleStatus(row.id, next)
  ElMessage.success(`${action}成功`)
  loadList()
}

onMounted(() => {
  loadList()
  loadParentOptions()
  loadFirstLevelDepartments()
})
</script>

<template>
  <div>
    <el-card class="filter-card" shadow="never">
      <el-form :inline="true" :model="query" @submit.prevent>
        <el-form-item label="名称">
          <el-input v-model="query.name" placeholder="科室名称" clearable @keyup.enter="handleSearch" />
        </el-form-item>
        <el-form-item label="科室">
          <el-select v-model="query.parentId" placeholder="全部" clearable style="width: 160px" @change="handleSearch">
            <el-option v-for="dept in firstLevelDepartments" :key="dept.id" :label="dept.name" :value="dept.id" />
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
        <span class="toolbar-title">科室列表</span>
        <el-button type="primary" :icon="Plus" @click="openCreate">新增科室</el-button>
      </div>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column type="index" label="序号" width="60" align="center" :index="(index) => (query.page - 1) * query.size + index + 1" />
        <el-table-column prop="code" label="编码" width="120" />
        <el-table-column prop="name" label="名称" min-width="150" show-overflow-tooltip />
        <el-table-column prop="departmentType" label="类型" width="100" align="center">
          <template #default>门诊</template>
        </el-table-column>
        <el-table-column prop="parentName" label="所属科室" width="110" />
        <el-table-column prop="description" label="说明" min-width="160" show-overflow-tooltip class-name="cell-left" />
        <el-table-column label="状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="row.enabled === 1 ? 'success' : 'info'">{{ row.enabled === 1 ? '已启用' : '已停用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="220" align="center">
          <template #default="{ row }">
            <el-button link type="primary" :icon="Edit" @click="openEdit(row)">编辑</el-button>
            <el-button link :type="row.enabled === 1 ? 'warning' : 'success'" @click="handleToggleStatus(row)">
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

    <el-dialog v-model="dialogVisible" :title="dialogMode === 'create' ? '新增科室' : '编辑科室'" width="480px">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="90px">
        <el-form-item label="编码" prop="code">
          <el-input v-model="form.code" />
        </el-form-item>
        <el-form-item label="名称" prop="name">
          <el-input v-model="form.name" />
        </el-form-item>
        <el-form-item label="类型">
          <el-select v-model="form.departmentType" style="width: 100%">
            <el-option v-for="item in DEPARTMENT_TYPES" :key="item.value" :label="item.label" :value="item.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="父级科室">
          <el-select v-model="form.parentId" style="width: 100%">
            <el-option v-if="dialogMode === 'create'" label="无（一级科室）" :value="0" />
            <el-option v-for="dept in parentOptions" :key="dept.id" :label="dept.name" :value="dept.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="排序">
          <el-input-number v-model="form.sortNo" :min="0" />
        </el-form-item>
        <el-form-item label="说明">
          <el-input v-model="form.description" type="textarea" :rows="2" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>
