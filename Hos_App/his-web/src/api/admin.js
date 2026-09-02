import request from './request'

/**
 * 后台 CRUD 接口统一形态（docs/07-RESTful接口契约.md §3.5）：
 * 列表 GET {base}/list，新增 POST {base}，编辑 PUT {base}/{id}，
 * 停用/启用 PUT {base}/{id}/status，逻辑删除 DELETE {base}/{id}。
 */
function createResourceApi(basePath) {
  return {
    list(params) {
      return request.get(`${basePath}/list`, { params })
    },
    create(data) {
      return request.post(basePath, data)
    },
    update(id, data) {
      return request.put(`${basePath}/${id}`, data)
    },
    toggleStatus(id, enabled) {
      return request.put(`${basePath}/${id}/status`, { enabled })
    },
    remove(id) {
      return request.delete(`${basePath}/${id}`)
    },
  }
}

export const userApi = createResourceApi('/api/admin/users')
export const departmentApi = createResourceApi('/api/admin/departments')
export const doctorApi = createResourceApi('/api/admin/doctors')
export const scheduleRuleApi = createResourceApi('/api/admin/schedule-rules')
export const levelApi = createResourceApi('/api/admin/levels')

export const orderApi = {
  list(params) {
    return request.get('/api/admin/orders/list', { params })
  },
  cancel(id) {
    return request.put(`/api/admin/orders/${id}/cancel`)
  },
}
