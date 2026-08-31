import { defineStore } from 'pinia'

const TOKEN_KEY = 'his_admin_token'
const USER_KEY = 'his_admin_user'

export const useAuthStore = defineStore('auth', {
  state: () => ({
    token: localStorage.getItem(TOKEN_KEY) || '',
    user: JSON.parse(localStorage.getItem(USER_KEY) || 'null'),
  }),
  getters: {
    isLoggedIn: (state) => Boolean(state.token),
  },
  actions: {
    setSession(loginResponse) {
      this.token = loginResponse.accessToken
      this.user = {
        userId: loginResponse.userId,
        nickname: loginResponse.nickname,
        userType: loginResponse.userType,
      }
      localStorage.setItem(TOKEN_KEY, this.token)
      localStorage.setItem(USER_KEY, JSON.stringify(this.user))
    },
    logout() {
      this.token = ''
      this.user = null
      localStorage.removeItem(TOKEN_KEY)
      localStorage.removeItem(USER_KEY)
    },
  },
})
