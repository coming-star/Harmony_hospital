<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { departmentApi } from '../api/admin'
import request from '../api/request'

const DEPARTMENT_TYPES = [
  { label: '临床科室', value: 'CLINICAL' },
  { label: '医技科室', value: 'MEDICAL_TECHNOLOGY' },
  { label: '其他', value: 'OTHER' },
]

const loading = ref(false)
const tableData = ref([])
const total = ref(0)
const parentOptions = ref([])

const query = reactive({
  name: '',
  departmentType: '',
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

function handleSearch() {
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

onMounted(() => {
  loadList()
  loadParentOptions()
})
</script>

<template>
  <div>
    <el-form :inline="true" :model="query" @submit.prevent>
      <el-form-item label="名称">
        <el-input v-model="query.name" placeholder="科室名称" clearable @keyup.enter="handleSearch" />
      </el-form-item>
      <el-form-item label="类型">
        <el-select v-model="query.departmentType" placeholder="全部" clearable style="width: 160px">
          <el-option v-for="item in DEPARTMENT_TYPES" :key="item.value" :label="item.label" :value="item.value" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="handleSearch">查询</el-button>
        <el-button type="success" @click="openCreate">新增科室</el-button>
      </el-form-item>
    </el-form>

    <el-table v-loading="loading" :data="tableData" border>
      <el-table-column prop="code" label="编码" width="120" />
      <el-table-column prop="name" label="名称" width="160" />
      <el-table-column prop="departmentType" label="类型" width="140" />
      <el-table-column prop="parentId" label="父级科室ID" width="120" />
      <el-table-column prop="description" label="说明" show-overflow-tooltip />
      <el-table-column label="状态" width="100">
        <template #default="{ row }">
          <el-tag :type="row.enabled === 1 ? 'success' : 'info'">{{ row.enabled === 1 ? '已启用' : '已停用' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="160">
        <template #default="{ row }">
          <el-button link type="primary" @click="openEdit(row)">编辑</el-button>
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
            <el-option label="无（一级科室）" :value="0" />
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

<style scoped>
.pagination {
  margin-top: 16px;
  justify-content: flex-end;
}
</style>
