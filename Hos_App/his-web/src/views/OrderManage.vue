<script setup>
import { reactive, ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search, Refresh } from '@element-plus/icons-vue'
import { orderApi } from '../api/admin'

const STATUS_OPTIONS = [
  { label: '待支付', value: 'PENDING_PAYMENT' },
  { label: '已支付', value: 'PAID' },
  { label: '已完成', value: 'COMPLETED' },
  { label: '已取消', value: 'CANCELLED' },
]

const STATUS_TAG = {
  PENDING_PAYMENT: 'warning',
  PAID: 'success',
  COMPLETED: '',
  CANCELLED: 'info',
}

function statusLabel(status) {
  return STATUS_OPTIONS.find((item) => item.value === status)?.label || status
}

const loading = ref(false)
const tableData = ref([])
const total = ref(0)

const query = reactive({
  orderNo: '',
  patientKeyword: '',
  doctorName: '',
  visitDate: '',
  status: '',
  page: 1,
  size: 10,
})

const detailVisible = ref(false)
const detailRow = ref(null)

async function loadList() {
  loading.value = true
  try {
    const data = await orderApi.list(query)
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
  query.orderNo = ''
  query.patientKeyword = ''
  query.doctorName = ''
  query.visitDate = ''
  query.status = ''
  query.page = 1
  loadList()
}

function handleSizeChange() {
  query.page = 1
  loadList()
}

function openDetail(row) {
  detailRow.value = row
  detailVisible.value = true
}

async function handleCancel(row) {
  await ElMessageBox.confirm(`确认取消订单「${row.orderNo}」？将归还号源。`, '提示', { type: 'warning' })
  await orderApi.cancel(row.id)
  ElMessage.success('已取消')
  loadList()
}

onMounted(loadList)
</script>

<template>
  <div>
    <el-card class="filter-card" shadow="never">
      <el-form :inline="true" :model="query" label-width="90px" @submit.prevent>
        <div class="filter-row">
          <el-form-item label="订单号">
            <el-input v-model="query.orderNo" placeholder="订单号" clearable style="width: 200px" @keyup.enter="handleSearch" />
          </el-form-item>
          <el-form-item label="患者/就诊人">
            <el-input v-model="query.patientKeyword" placeholder="手机号或姓名" clearable style="width: 200px" @keyup.enter="handleSearch" />
          </el-form-item>
        </div>
        <div class="filter-row">
          <el-form-item label="医生">
            <el-input v-model="query.doctorName" placeholder="医生姓名" clearable style="width: 200px" @keyup.enter="handleSearch" />
          </el-form-item>
          <el-form-item label="就诊日期">
            <el-date-picker v-model="query.visitDate" type="date" value-format="YYYY-MM-DD" placeholder="选择日期" style="width: 200px" @change="handleSearch" />
          </el-form-item>
          <el-form-item label="状态">
            <el-select v-model="query.status" placeholder="全部" clearable style="width: 200px" @change="handleSearch">
              <el-option v-for="item in STATUS_OPTIONS" :key="item.value" :label="item.label" :value="item.value" />
            </el-select>
          </el-form-item>
          <el-form-item>
            <el-button type="primary" :icon="Search" @click="handleSearch">查询</el-button>
            <el-button :icon="Refresh" @click="handleReset">重置</el-button>
          </el-form-item>
        </div>
      </el-form>
    </el-card>

    <el-card class="table-card" shadow="never">
      <div class="toolbar">
        <span class="toolbar-title">挂号记录</span>
      </div>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column type="index" label="序号" width="60" align="center" :index="(index) => (query.page - 1) * query.size + index + 1" />
        <el-table-column prop="orderNo" label="订单号" min-width="180" show-overflow-tooltip />
        <el-table-column prop="doctorName" label="医生" width="100" />
        <el-table-column prop="departmentName" label="科室" min-width="110" show-overflow-tooltip />
        <el-table-column prop="levelName" label="号别" width="90" />
        <el-table-column prop="visitDate" label="就诊日期" width="110" />
        <el-table-column label="时段" width="130">
          <template #default="{ row }">{{ row.startTime }} - {{ row.endTime }}</template>
        </el-table-column>
        <el-table-column label="金额（元）" width="100">
          <template #default="{ row }">{{ (row.amountFen / 100).toFixed(2) }}</template>
        </el-table-column>
        <el-table-column label="状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="STATUS_TAG[row.status]">{{ statusLabel(row.status) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="160" align="center">
          <template #default="{ row }">
            <el-button link type="primary" @click="openDetail(row)">详情</el-button>
            <el-button
              v-if="row.status === 'PENDING_PAYMENT' || row.status === 'PAID'"
              link
              type="danger"
              @click="handleCancel(row)"
            >
              取消
            </el-button>
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

    <el-dialog v-model="detailVisible" title="订单详情" width="480px">
      <el-descriptions :column="1" border v-if="detailRow">
        <el-descriptions-item label="订单号">{{ detailRow.orderNo }}</el-descriptions-item>
        <el-descriptions-item label="状态">{{ statusLabel(detailRow.status) }}</el-descriptions-item>
        <el-descriptions-item label="医生">{{ detailRow.doctorName }}</el-descriptions-item>
        <el-descriptions-item label="科室">{{ detailRow.departmentName }}</el-descriptions-item>
        <el-descriptions-item label="号别">{{ detailRow.levelName }}</el-descriptions-item>
        <el-descriptions-item label="就诊时间">
          {{ detailRow.visitDate }} {{ detailRow.startTime }} - {{ detailRow.endTime }}
        </el-descriptions-item>
        <el-descriptions-item label="金额">{{ (detailRow.amountFen / 100).toFixed(2) }} 元</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ detailRow.createdAt }}</el-descriptions-item>
        <el-descriptions-item label="支付时间">{{ detailRow.paidAt || '-' }}</el-descriptions-item>
        <el-descriptions-item label="取消时间">{{ detailRow.cancelledAt || '-' }}</el-descriptions-item>
        <el-descriptions-item label="取消原因">{{ detailRow.cancelReason || '-' }}</el-descriptions-item>
      </el-descriptions>
    </el-dialog>
  </div>
</template>

<style scoped>
.filter-row {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
}

.filter-row + .filter-row {
  margin-top: 20px;
}
</style>
