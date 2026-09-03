import { get } from '../utils/request'
import type { DoctorDetailResponse } from '../types'

/** 医生详情：含所属科室名 + 可提供的挂号级别列表 */
export function getDoctorDetail(id: string | number): Promise<DoctorDetailResponse> {
  return get<DoctorDetailResponse>(`/api/doctors/${id}`)
}
