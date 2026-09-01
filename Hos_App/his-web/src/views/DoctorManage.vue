<script setup>
import { reactive, ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Edit, Delete } from '@element-plus/icons-vue'
import { doctorApi } from '../api/admin'

const loading = ref(false)
const tableData = ref([])
const total = ref(0)

// 一级科室选项：内科、外科、儿科、妇科
const deptLevel1Options = ref([
  { label: '内科', value: '内科' },
  { label: '外科', value: '外科' },
  { label: '儿科', value: '儿科' },
  { label: '妇科', value: '妇科' }
])

// 查询参数
const query = reactive({
  name: '',
  deptName: '',
  page: 1,
  size: 10
})

// 模拟样例数据，完全对齐截图业务
const mockDoctorList = [
  {
    id:1, name:'陈明远', title:'主任医师', deptName:'内科',
    intro:'从事心血管内科临床与教学工作二十余年，擅长高血压、冠心病诊疗。',
    enabled:1,
    schedules:[
      {level:'专家号', ruleText:'星期一三五上午'}
    ]
  },
  {
    id:2, name:'周宁', title:'副主任医师', deptName:'内科',
    intro:'擅长心血管常见病诊治及慢病随访。',
    enabled:1,
    schedules:[
      {level:'专家号', ruleText:'工作日上午'}
    ]
  },
  {
    id:3, name:'赵安然', title:'主任医师', deptName:'内科',
    intro:'擅长脑血管疾病、头痛眩晕与睡眠障碍诊治。',
    enabled:1,
    schedules:[
      {level:'专家号', ruleText:'星期二四六下午'}
    ]
  },
  {
    id:4, name:'孙悦', title:'主治医师', deptName:'内科',
    intro:'擅长胃肠道疾病、脂肪肝及消化不良诊疗。',
    enabled:1,
    schedules:[
      {level:'普通号', ruleText:'工作日下午'}
    ]
  },
  {
    id:5, name:'何志诚', title:'副主任医师', deptName:'外科',
    intro:'擅长慢性咳嗽、哮喘及呼吸道感染诊疗。',
    enabled:1,
    schedules:[
      {level:'专家号', ruleText:'周一至周六上午'}
    ]
  },
  {
    id:6, name:'吴清雅', title:'主任医师', deptName:'外科',
    intro:'擅长甲状腺、乳腺及胃肠外科常见疾病。',
    enabled:1,
    schedules:[
      {level:'专家号', ruleText:'周二周四上午'}
    ]
  },
  {
    id:7, name:'林峰', title:'副主任医师', deptName:'外科',
    intro:'擅长关节运动损伤、骨折康复及脊柱退变性疾病。',
    enabled:1,
    schedules:[
      {level:'专家号', ruleText:'工作日下午'}
    ]
  },
  {
    id:8, name:'许星河', title:'主治医师', deptName:'儿科',
    intro:'擅长儿童呼吸道、消化道常见病和儿童保健。',
    enabled:1,
    schedules:[
      {level:'普通号', ruleText:'每天上午'}
    ]
  },
  {
    id:9, name:'唐静', title:'副主任医师', deptName:'妇科',
    intro:'擅长妇科炎症、月经异常及妇科常见疾病诊疗。',
    enabled:1,
    schedules:[
      {level:'专家号', ruleText:'工作日上午'}
    ]
  },
  {
    id:10,name:'高文博', title:'主治医师', deptName:'内科',
    intro:'擅长中医内科常见病辨证调理和亚健康管理。',
    enabled:1,
    schedules:[
      {level:'普通号', ruleText:'周一至周六下午'}
    ]
  }
]

const dialogVisible = ref(false)
const dialogMode = ref('create')
const formRef = ref()
const form = reactive({
  id: null,
  name: '',
  title: '',
  deptName: '',
  intro: '',
  enabled: 1
})

const rules = {
  name: [{ required: true, message: '请输入姓名', trigger: 'blur' }],
  title: [{ required: true, message: '请输入职称', trigger: 'blur' }],
  deptName: [{ required: true, message: '请选择一级科室', trigger: 'change' }],
  intro: [{ required: true, message: '请输入简介', trigger: 'blur' }]
}

async function loadList() {
  loading.value = true
  try {
    // 模拟过滤逻辑
    let filterList = [...mockDoctorList]
    if(query.name){
      filterList = filterList.filter(item=>item.name.includes(query.name))
    }
    if(query.deptName){
      filterList = filterList.filter(item=>item.deptName === query.deptName)
    }
    tableData.value = filterList
    total.value = filterList.length

    // =========对接后端，注释上面模拟，打开下面接口=========
    // const res = await doctorApi.list(query)
    // tableData.value = res.records
    // total.value = res.total
  } finally {
    loading.value = false
  }
}

// 查询
function handleSearch() {
  query.page = 1
  loadList()
}
//重置
function handleReset() {
  query.name = ''
  query.deptName = ''
  query.page = 1
  loadList()
}

function openCreate() {
  dialogMode.value = 'create'
  Object.assign(form, {
    id: null, name: '', title: '', deptName: '', intro: '', enabled:1
  })
  dialogVisible.value = true
}

function openEdit(row) {
  dialogMode.value = 'edit'
  Object.assign(form, {...row})
  dialogVisible.value = true
}

async function handleSubmit() {
  await formRef.value.validate()
  if(dialogMode.value === 'create'){
    await doctorApi.create(form)
  }else{
    await doctorApi.update(form.id, form)
  }
  ElMessage.success('保存成功')
  dialogVisible.value = false
  loadList()
}

async function toggleStatus(row) {
  const nextStatus = row.enabled ===1 ? 0 : 1
  await doctorApi.toggleStatus(row.id, nextStatus)
  ElMessage.success('操作成功')
  loadList()
}

async function handleDelete(row) {
  await ElMessageBox.confirm(`确认删除医生【${row.name}】？`, '提示', {type:'warning'})
  await doctorApi.remove(row.id)
  ElMessage.success('删除成功')
  loadList()
}

function handleSizeChange(){
  query.page=1
  loadList()
}

onMounted(()=>{
  loadList()
})
</script>

<template>
  <div class="doctor-page">
    <el-card shadow="never">
      <!-- 查询区域：姓名 +一级科室下拉 -->
      <el-form inline :model="query">
        <el-form-item label="姓名">
          <el-input v-model="query.name" placeholder="医生姓名" clearable></el-input>
        </el-form-item>
        <el-form-item label="科室">
          <el-select v-model="query.deptName" placeholder="全部" clearable style="width:160px">
            <el-option v-for="d in deptLevel1Options" :key="d.value" :label="d.label" :value="d.value"/>
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSearch">查询</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card shadow="never" style="margin-top:12px">
      <div class="table-header">
        <h3>医生列表</h3>
        <el-button type="primary" :icon="Plus" @click="openCreate">新增医生</el-button>
      </div>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <!-- 序号，去掉头像 -->
        <el-table-column type="index" label="序号" width="60" align="center"
          :index="(idx) => (query.page-1)*query.size + idx +1"/>
        <el-table-column prop="name" label="姓名" width="100"/>
        <el-table-column prop="title" label="职称" width="120"/>
        <!-- 科室ID改为一级科室名称 -->
        <el-table-column prop="deptName" label="科室" width="100"/>
        <el-table-column prop="intro" label="简介" min-width="220" show-overflow-tooltip/>

        <!-- 新增：挂号级别列 -->
        <el-table-column label="挂号级别" width="130">
          <template #default="{row}">
            <el-tag
              v-for="sch in row.schedules"
              :key="sch.level"
              size="small"
              style="margin:0 4px 4px 0"
              :type="sch.level === '专家号' ? 'warning' : ''"
            >
              {{ sch.level }}
            </el-tag>
          </template>
        </el-table-column>

        <!-- 新增：排班规则列 -->
        <el-table-column label="排班规则" min-width="240">
          <template #default="{row}">
            <el-tag
              v-for="sch in row.schedules"
              :key="sch.ruleText"
              size="small"
              type="success"
              style="margin:0 4px 4px 0"
            >
              {{ sch.ruleText }}
            </el-tag>
          </template>
        </el-table-column>

        <el-table-column label="状态" width="100" align="center">
          <template #default="{row}">
            <el-tag :type="row.enabled===1?'success':'info'">
              {{ row.enabled===1 ? '已启用' : '已停用' }}
            </el-tag>
          </template>
        </el-table-column>

        <el-table-column label="操作" width="240" align="center">
          <template #default="{row}">
            <el-button link type="primary" :icon="Edit" @click="openEdit(row)">编辑</el-button>
            <el-button link type="warning" @click="toggleStatus(row)">
              {{ row.enabled===1 ? '停用' : '启用' }}
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
          :page-sizes="[10,20,50,100]"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="loadList"
        />
      </div>
    </el-card>

    <!-- 新增编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogMode==='create'?'新增医生':'编辑医生'" width="520px">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="90px">
        <el-form-item label="姓名" prop="name">
          <el-input v-model="form.name"></el-input>
        </el-form-item>
        <el-form-item label="职称" prop="title">
          <el-input v-model="form.title"></el-input>
        </el-form-item>
        <el-form-item label="科室" prop="deptName">
          <el-select v-model="form.deptName" style="width:100%">
            <el-option v-for="d in deptLevel1Options" :key="d.value" :label="d.label" :value="d.value"/>
          </el-select>
        </el-form-item>
        <el-form-item label="简介" prop="intro">
          <el-input v-model="form.intro" type="textarea" :rows="3"></el-input>
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
.table-header{
  display:flex;
  justify-content:space-between;
  align-items:center;
  margin-bottom:14px;
}
.pagination-wrap{
  margin-top:16px;
  display:flex;
  justify-content:flex-end;
}
</style>
