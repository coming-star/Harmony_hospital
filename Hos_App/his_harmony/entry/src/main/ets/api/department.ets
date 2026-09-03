import { get } from '../utils/request'
import type { DepartmentTreeNode } from '../types'

/** 两级科室树（已启用科室，parentId=0 为一级）*/
export function getDepartmentTree(): Promise<DepartmentTreeNode[]> {
  return get<DepartmentTreeNode[]>('/api/departments/tree')
}
