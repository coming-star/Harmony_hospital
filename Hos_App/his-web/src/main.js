import { createApp } from 'vue'
import { createPinia } from 'pinia'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import './theme.css'
import App from './App.vue'
import router from './router'
import zhCn from 'element-plus/dist/locale/zh-cn.mjs'

const app = createApp(App)

app.use(createPinia())
app.use(router)
// 只use一次ElementPlus，把locale配置放这里
app.use(ElementPlus, {
  locale: zhCn
})

app.mount('#app')
