import { BaseRequest, httpClient, JsonBody, QueryParams } from './httpClient';

export interface JwtVO {
  accessToken: string;
  refreshToken: string;
  username: string;
}

class AuthApi {
  login(username: string, password: string): Promise<JwtVO> {
    const data = new JsonBody()
      .put('username', username)
      .put('password', password)
      .build();
    const options: BaseRequest = { data, showSuccess: true };
    return httpClient.post<JwtVO>('/auth/login', options);
  }

  refresh(refreshToken: string): Promise<JwtVO> {
    const params = new QueryParams().put('refreshToken', refreshToken);
    const options: BaseRequest = {
      params,
      showError: false,
      skipAuthRefresh: true
    };
    return httpClient.get<JwtVO>('/auth/refresh', options);
  }

  async logout(refreshToken: string, showSuccess?: boolean): Promise<void> {
    const params = new QueryParams().put('refreshToken', refreshToken);
    const options: BaseRequest = {
      params,
      showSuccess,
      skipAuthRefresh: true
    };
    await httpClient.get<void>('/auth/logout', options);
  }
}

export const authApi = new AuthApi();
