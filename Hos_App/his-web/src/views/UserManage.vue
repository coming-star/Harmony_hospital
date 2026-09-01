<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search, Plus, Edit, Delete } from '@element-plus/icons-vue'
import { userApi } from '../api/admin'

const loading = ref(false)
const tableData = ref([])
const total = ref(0)

const query = reactive({
  phone: '',
  status: '',
  page: 1,
  size: 10,
})

const dialogVisible = ref(false)
const dialogMode = ref('create')
const formRef = ref()
const form = reactive({
  id: null,
  phone: '',
  nickname: '',
  password: '',
  status: 1,
})

const rules = {
  phone: [{ required: true, message: '请输入手机号', trigger: 'blur' }],
  nickname: [{ required: true, message: '请输入昵称', trigger: 'blur' }],
  password: [{ required: true, message: '请输入初始密码', trigger: 'blur' }],
}

async function loadList() {
  loading.value = true
  try {
    const data = await userApi.list(query)
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

function handleSizeChange() {
  query.page = 1
  loadList()
}

function openCreate() {
  dialogMode.value = 'create'
  Object.assign(form, { id: null, phone: '', nickname: '', password: '', status: 1 })
  dialogVisible.value = true
}

function openEdit(row) {
  dialogMode.value = 'edit'
  Object.assign(form, { ...row, password: '' })
  dialogVisible.value = true
}

async function handleSubmit() {
  await formRef.value.validate()
  if (dialogMode.value === 'create') {
    await userApi.create(form)
  } else {
    await userApi.update(form.id, form)
  }
  ElMessage.success('保存成功')
  dialogVisible.value = false
  loadList()
}

async function handleToggleStatus(row) {
  const nextEnabled = row.status === 1 ? 0 : 1
  await userApi.toggleStatus(row.id, nextEnabled)
  ElMessage.success('操作成功')
  loadList()
}

async function handleDelete(row) {
  await ElMessageBox.confirm(`确认删除用户「${row.nickname}」？`, '提示', { type: 'warning' })
  await userApi.remove(row.id)
  ElMessage.success('删除成功')
  loadList()
}

onMounted(loadList)
</script>

<template>
  <div>
    <el-card class="filter-card" shadow="never">
      <el-form :inline="true" :model="query" @submit.prevent>
        <el-form-item label="手机号">
          <el-input v-model="query.phone" placeholder="手机号" clearable @keyup.enter="handleSearch" />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" placeholder="全部" clearable style="width: 120px">
            <el-option label="启用" :value="1" />
            <el-option label="停用" :value="0" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :icon="Search" @click="handleSearch">查询</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card class="table-card" shadow="never">
      <div class="toolbar">
        <span class="toolbar-title">用户列表</span>
        <el-button type="primary" :icon="Plus" @click="openCreate">新增用户</el-button>
      </div>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column type="index" label="序号" width="60" align="center" :index="(index) => (query.page - 1) * query.size + index + 1" />
        <el-table-column prop="phone" label="手机号" width="140" />
        <el-table-column prop="nickname" label="昵称" width="140" />
        <el-table-column prop="userType" label="类型" width="100">
          <template #default>门诊</template>
        </el-table-column>
        <el-table-column prop="createdAt" label="注册日期" width="180" />
        <el-table-column prop="lastLoginAt" label="最后登录" width="180" />
        <el-table-column label="状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'info'">{{ row.status === 1 ? '启用' : '停用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="220" align="center">
          <template #default="{ row }">
            <el-button link type="primary" :icon="Edit" @click="openEdit(row)">编辑</el-button>
            <el-button link type="warning" @click="handleToggleStatus(row)">
              {{ row.status === 1 ? '停用' : '启用' }}
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

    <el-dialog v-model="dialogVisible" :title="dialogMode === 'create' ? '新增用户' : '编辑用户'" width="420px">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="80px">
        <el-form-item label="手机号" prop="phone">
          <el-input v-model="form.phone" />
        </el-form-item>
        <el-form-item label="昵称" prop="nickname">
          <el-input v-model="form.nickname" />
        </el-form-item>
        <el-form-item v-if="dialogMode === 'create'" label="初始密码" prop="password">
          <el-input v-model="form.password" type="password" show-password />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>
