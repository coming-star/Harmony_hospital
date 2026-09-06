import { uploadFile, type UploadResult } from '../utils/request'

/** 上传头像图片 → 返回可直接访问的头像 URL */
export function uploadAvatar(fileUri: string): Promise<UploadResult> {
  return uploadFile('/api/upload/avatar', fileUri, 'file', { loading: true })
}
