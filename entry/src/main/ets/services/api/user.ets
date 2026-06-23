import { BaseRequest, httpClient, JsonBody } from './httpClient';

export interface Role {
  id: number;
  name: string;
  description: string;
  parentNodeId: number;
  level: number;
  createTime: string;
  updateTime: string;
}

export interface UserVO {
  id: number;
  username: string;
  name: string;
  avatarUrl: string;
  sex: string;
  signature?: string;
  hasPermission: boolean;
  roles: Role[];
  isValid: boolean;
  createTime: string;
  updateTime: string;
}

export interface UpdateUserDTO {
  id: number;
  name?: string;
  avatarUrl?: string;
  sex?: string;
  signature?: string;
}

export interface ChangePasswordDTO {
  currentPassword: string;
  newPassword: string;
  confirmPassword: string;
}

class UserApi {
  getUser(): Promise<UserVO> {
    return httpClient.get<UserVO>('/user/get');
  }

  updateUser(userInfo: UpdateUserDTO, showSuccess?: boolean): Promise<void> {
    const options: BaseRequest = {
      data: JsonBody.from(userInfo),
      showSuccess
    };
    return httpClient.post<void>('/user/update', options);
  }

  changePassword(password: ChangePasswordDTO, showSuccess?: boolean): Promise<void> {
    const options: BaseRequest = {
      data: JsonBody.from(password),
      showSuccess
    };
    return httpClient.post<void>('/user/change-password', options);
  }
}

export const userApi = new UserApi();
