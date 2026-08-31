import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../store/auth'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/Login.vue'),
  },
  {
    path: '/',
    component: () => import('../layout/AdminLayout.vue'),
    redirect: '/dashboard',
    children: [
      { path: 'dashboard', name: 'Dashboard', component: () => import('../views/Dashboard.vue'), meta: { title: '工作台' } },
      { path: 'users', name: 'UserManage', component: () => import('../views/UserManage.vue'), meta: { title: '用户管理' } },
      { path: 'departments', name: 'DepartmentManage', component: () => import('../views/DepartmentManage.vue'), meta: { title: '科室管理' } },
      { path: 'doctors', name: 'DoctorManage', component: () => import('../views/DoctorManage.vue'), meta: { title: '医生管理' } },
      { path: 'schedule-rules', name: 'ScheduleRuleManage', component: () => import('../views/ScheduleRuleManage.vue'), meta: { title: '排班管理' } },
      { path: 'levels', name: 'LevelManage', component: () => import('../views/LevelManage.vue'), meta: { title: '挂号级别' } },
      { path: 'orders', name: 'OrderManage', component: () => import('../views/OrderManage.vue'), meta: { title: '挂号记录' } },
    ],
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach((to) => {
  const authStore = useAuthStore()

  if (to.name !== 'Login' && !authStore.isLoggedIn) {
    return { name: 'Login', query: { redirect: to.fullPath } }
  }

  if (to.name === 'Login' && authStore.isLoggedIn) {
    return { path: '/dashboard' }
  }

  return true
})

export default router
