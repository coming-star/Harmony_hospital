/**
 * 全局格式化工具：金额（分→元）、日期、手机号打码、身份证打码等。
 */
export class Format {
  /** 金额：后端返回的「分」→ 前端展示的「元」，保留 0/1/2 位小数，带 ¥ 前缀。 */
  static yuan(fen: number | string | null | undefined, withPrefix = true): string {
    if (fen === null || fen === undefined || fen === '') return withPrefix ? '¥0' : '0'
    const n = typeof fen === 'number' ? fen : parseInt(String(fen), 10)
    if (isNaN(n)) return withPrefix ? '¥0' : '0'
    const str = (n / 100).toFixed(n % 100 === 0 ? 0 : (n % 10 === 0 ? 1 : 2))
    return withPrefix ? `¥${str}` : str
  }

  /** 日期格式化：LocalDate 样式字符串 / Date 对象 → yyyy-MM-dd */
  static date(v: string | Date | null | undefined): string {
    if (!v) return ''
    const d = typeof v === 'string' ? new Date(v) : v
    if (isNaN(d.getTime())) return String(v).slice(0, 10)
    const y = d.getFullYear()
    const m = String(d.getMonth() + 1).padStart(2, '0')
    const day = String(d.getDate()).padStart(2, '0')
    return `${y}-${m}-${day}`
  }

  /** 日期+时间格式化 */
  static datetime(v: string | Date | null | undefined): string {
    if (!v) return ''
    const d = typeof v === 'string' ? new Date(v) : v
    if (isNaN(d.getTime())) return String(v).slice(0, 16).replace('T', ' ')
    const date = Format.date(d)
    const hh = String(d.getHours()).padStart(2, '0')
    const mm = String(d.getMinutes()).padStart(2, '0')
    return `${date} ${hh}:${mm}`
  }

  /** 时间 HH:mm */
  static time(v: string | Date | null | undefined): string {
    if (!v) return ''
    // 后端 LocalTime 直接返回 "08:00:00"；也兼容 Date 对象
    if (typeof v === 'string' && v.includes(':')) return v.slice(0, 5)
    const d = typeof v === 'string' ? new Date(v) : v as Date
    return `${String(d.getHours()).padStart(2,'0')}:${String(d.getMinutes()).padStart(2,'0')}`
  }

  /** 手机号打码：138****0002 */
  static maskPhone(p: string | null | undefined): string {
    if (!p || p.length < 7) return p ?? ''
    return p.slice(0, 3) + '****' + p.slice(-4)
  }

  /** 姓名打码：张* / 张**国（最小化脱敏，挂号演示也可以关，按需调用）*/
  static maskName(name: string | null | undefined): string {
    if (!name) return ''
    if (name.length === 1) return name
    if (name.length === 2) return name.charAt(0) + '*'
    return name.charAt(0) + '*'.repeat(name.length - 2) + name.charAt(name.length - 1)
  }

  /** 星期：0-6 周日-周六 → 一/二/三/四/五/六/日 */
  static weekday(dateLike: string | Date): string {
    const d = typeof dateLike === 'string' ? new Date(dateLike) : dateLike
    const arr = ['日', '一', '二', '三', '四', '五', '六']
    return '周' + arr[d.getDay()]
  }

  /** 未来 7 天（含今天）日期数组：[{ iso, mmdd, weekday }]，用于医生列表页顶部 7 天切换条 */
  static next7Days(offsetDays = 0): Array<{ iso: string; mmdd: string; weekday: string; isToday: boolean }> {
    const result: Array<{ iso: string; mmdd: string; weekday: string; isToday: boolean }> = []
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    for (let i = offsetDays; i < offsetDays + 7; i++) {
      const d = new Date(today.getTime() + i * 86400000)
      result.push({
        iso: Format.date(d),
        mmdd: `${String(d.getMonth() + 1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`,
        weekday: Format.weekday(d).replace('周', ''),
        isToday: i === 0
      })
    }
    return result
  }

  /** 生成 UUID（用作 idempotencyKey）：格式 8-4-4-4-12，不依赖环境 crypto */
  static uuid(): string {
    const hex = '0123456789abcdef'
    const rnd = (n: number) => {
      let s = ''
      for (let i = 0; i < n; i++) s += hex.charAt(Math.floor(Math.random() * 16))
      return s
    }
    return `${rnd(8)}-${rnd(4)}-4${rnd(3)}-${hex.charAt((Math.random()*4)|8)}${rnd(3)}-${rnd(12)}`
  }
}
