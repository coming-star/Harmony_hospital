<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Edit, Delete } from '@element-plus/icons-vue'
import { levelApi } from '../api/admin'

const loading = ref(false)
const tableData = ref([])
const total = ref(0)

const query = reactive({
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
  feeYuan: 0,
  defaultQuota: 0,
  sortNo: 0,
})

const rules = {
  code: [{ required: true, message: '请输入编码', trigger: 'blur' }],
  name: [{ required: true, message: '请输入名称', trigger: 'blur' }],
}

async function loadList() {
  loading.value = true
  try {
    const data = await levelApi.list(query)
    tableData.value = data.records
    total.value = data.total
  } finally {
    loading.value = false
  }
}

function handleSizeChange() {
  query.page = 1
  loadList()
}

function openCreate() {
  dialogMode.value = 'create'
  Object.assign(form, { id: null, code: '', name: '', feeYuan: 0, defaultQuota: 0, sortNo: 0 })
  dialogVisible.value = true
}

function openEdit(row) {
  dialogMode.value = 'edit'
  Object.assign(form, { ...row, feeYuan: (row.feeFen || 0) / 100 })
  dialogVisible.value = true
}

async function handleSubmit() {
  await formRef.value.validate()
  const payload = { ...form, feeFen: Math.round(form.feeYuan * 100) }
  if (dialogMode.value === 'create') {
    await levelApi.create(payload)
  } else {
    await levelApi.update(payload.id, payload)
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
  await levelApi.toggleStatus(row.id, nextEnabled)
  ElMessage.success('操作成功')
  loadList()
}

async function handleDelete(row) {
  await ElMessageBox.confirm(`确认删除挂号级别「${row.name}」？被医生/排班引用时将无法删除。`, '提示', { type: 'warning' })
  await levelApi.remove(row.id)
  ElMessage.success('删除成功')
  loadList()
}

onMounted(loadList)
</script>

<template>
  <div>
    <el-card class="table-card" shadow="never">
      <div class="toolbar">
        <span class="toolbar-title">挂号级别列表</span>
        <el-button type="primary" :icon="Plus" @click="openCreate">新增挂号级别</el-button>
      </div>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column type="index" label="序号" width="60" align="center" :index="(index) => (query.page - 1) * query.size + index + 1" />
        <el-table-column prop="code" label="编码" width="120" />
        <el-table-column prop="name" label="名称" min-width="150" show-overflow-tooltip />
        <el-table-column label="费用（元）" width="110">
          <template #default="{ row }">{{ (row.feeFen / 100).toFixed(2) }}</template>
        </el-table-column>
        <el-table-column prop="defaultQuota" label="默认限额" width="100" />
        <el-table-column prop="sortNo" label="排序" width="80" align="center" />
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

    <el-dialog v-model="dialogVisible" :title="dialogMode === 'create' ? '新增挂号级别' : '编辑挂号级别'" width="420px">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="90px">
        <el-form-item label="编码" prop="code">
          <el-input v-model="form.code" />
        </el-form-item>
        <el-form-item label="名称" prop="name">
          <el-input v-model="form.name" />
        </el-form-item>
        <el-form-item label="费用（元）">
          <el-input-number v-model="form.feeYuan" :min="0" :precision="2" :step="1" />
        </el-form-item>
        <el-form-item label="默认限额">
          <el-input-number v-model="form.defaultQuota" :min="0" />
        </el-form-item>
        <el-form-item label="排序">
          <el-input-number v-model="form.sortNo" :min="0" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>
