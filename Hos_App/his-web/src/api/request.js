import axios from 'axios'
import { ElMessage } from 'element-plus'
import { useAuthStore } from '../store/auth'
import router from '../router'

const request = axios.create({
  baseURL: 'http://localhost:8081',
  timeout: 10000,
})

request.interceptors.request.use((config) => {
  const authStore = useAuthStore()
  if (authStore.token) {
    config.headers.Authorization = `Bearer ${authStore.token}`
  }
  return config
})

request.interceptors.response.use(
  (response) => {
    const body = response.data
    if (body.code !== 200) {
      ElMessage.error(body.message || '请求失败')
      return Promise.reject(body)
    }
    return body.data
  },
  (error) => {
    const status = error.response?.status
    const message = error.response?.data?.message || error.message || '网络异常'

    if (status === 401) {
      const authStore = useAuthStore()
      authStore.logout()
      router.push('/login')
    }

    ElMessage.error(message)
    return Promise.reject(error)
  }
)

export default request
