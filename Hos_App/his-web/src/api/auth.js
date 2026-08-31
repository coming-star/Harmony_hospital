import request from './request'

export function adminLogin(data) {
  return request.post('/api/admin/auth/login', data)
}

export function adminLogout() {
  return request.post('/api/admin/auth/logout')
}
