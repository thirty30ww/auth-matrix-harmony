import http from '@ohos.net.http';

export interface ApiResponse<T> {
  code: number;
  data: T;
  message: string;
}

export interface BaseRequest {
  data?: string;
  params?: QueryParams;
  showError?: boolean;
  showSuccess?: boolean;
  skipAuthRefresh?: boolean;
}

export type RefreshHandler = () => Promise<boolean>;

export class JsonBody {
  private keys: string[] = [];
  private values: string[] = [];

  put(key: string, value: string): JsonBody {
    this.keys.push(key);
    this.values.push(value);
    return this;
  }

  static from<T>(value: T): string {
    return JSON.stringify(value);
  }

  build(): string {
    const parts: string[] = [];
    for (let i = 0; i < this.keys.length; i++) {
      parts.push(`${JSON.stringify(this.keys[i])}:${JSON.stringify(this.values[i])}`);
    }
    return `{${parts.join(',')}}`;
  }
}

export class QueryParams {
  private keys: string[] = [];
  private values: string[] = [];

  put(key: string, value: string | number | boolean): QueryParams {
    this.keys.push(key);
    this.values.push(String(value));
    return this;
  }

  build(): string {
    const parts: string[] = [];
    for (let i = 0; i < this.keys.length; i++) {
      parts.push(`${encodeURIComponent(this.keys[i])}=${encodeURIComponent(this.values[i])}`);
    }
    return parts.join('&');
  }
}

export class HttpClient {
  private baseURL: string = 'http://localhost:8080';
  private accessToken: string = '';
  private refreshHandler: RefreshHandler | null = null;
  private refreshingPromise: Promise<boolean> | null = null;

  setBaseURL(url: string): void {
    this.baseURL = url.replace(/\/+$/, '');
  }

  setAccessToken(token: string): void {
    this.accessToken = token;
  }

  clearAccessToken(): void {
    this.accessToken = '';
  }

  setRefreshHandler(handler: RefreshHandler): void {
    this.refreshHandler = handler;
  }

  get<T>(path: string, options: BaseRequest = {}): Promise<T> {
    return this.request<T>(http.RequestMethod.GET, path, options);
  }

  post<T>(path: string, options: BaseRequest = {}): Promise<T> {
    return this.request<T>(http.RequestMethod.POST, path, options);
  }

  put<T>(path: string, options: BaseRequest = {}): Promise<T> {
    return this.request<T>(http.RequestMethod.PUT, path, options);
  }

  delete<T>(path: string, options: BaseRequest = {}): Promise<T> {
    return this.request<T>(http.RequestMethod.DELETE, path, options);
  }

  async uploadFile<T>(path: string, fileUri: string, fieldName: string = 'file'): Promise<T> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(this.buildURL(path), {
        method: http.RequestMethod.POST,
        header: this.buildUploadHeaders(),
        multiFormDataList: [{
          name: fieldName,
          contentType: 'image/jpeg',
          remoteFileName: 'avatar.jpg',
          filePath: fileUri
        }],
        expectDataType: http.HttpDataType.OBJECT,
        connectTimeout: 20000,
        readTimeout: 20000
      });

      const apiResponse = this.parseResponse<T>(response.result);
      if (this.isSuccessResponse(apiResponse)) {
        return apiResponse.data;
      }

      throw new Error(apiResponse.message || `请求失败: ${apiResponse.code}`);
    } catch (e) {
      const err = e as Error;
      throw new Error(err.message || '上传失败');
    } finally {
      httpRequest.destroy();
    }
  }

  private async request<T>(method: http.RequestMethod, path: string, options: BaseRequest, retried: boolean = false): Promise<T> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(this.buildURL(path, options.params), {
        method,
        header: this.buildHeaders(),
        extraData: options.data,
        expectDataType: http.HttpDataType.OBJECT,
        connectTimeout: 10000,
        readTimeout: 10000
      });

      const apiResponse = this.parseResponse<T>(response.result);
      if (this.isSuccessResponse(apiResponse)) {
        return apiResponse.data;
      }

      if (String(apiResponse.code) === '401' && !retried && !options.skipAuthRefresh && this.refreshHandler !== null) {
        const refreshed = await this.refreshAuth();
        if (refreshed) {
          return this.request<T>(method, path, options, true);
        }
      }

      throw new Error(apiResponse.message || `请求失败: ${apiResponse.code}`);
    } catch (e) {
      const err = e as Error;
      throw new Error(err.message || '服务器错误');
    } finally {
      httpRequest.destroy();
    }
  }

  private async refreshAuth(): Promise<boolean> {
    if (this.refreshingPromise !== null) {
      return this.refreshingPromise;
    }

    this.refreshingPromise = this.refreshHandler!();
    try {
      return await this.refreshingPromise;
    } finally {
      this.refreshingPromise = null;
    }
  }

  private buildURL(path: string, params?: QueryParams): string {
    let url = `${this.baseURL}${path.startsWith('/') ? path : `/${path}`}`;
    if (!params) {
      return url;
    }

    const query = params.build();
    if (query.length > 0) {
      url = `${url}?${query}`;
    }
    return url;
  }

  private buildHeaders(): Record<string, string> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };
    if (this.accessToken) {
      headers.Authorization = `Bearer ${this.accessToken}`;
    }
    return headers;
  }

  private parseResponse<T>(result: string | object | ArrayBuffer): ApiResponse<T> {
    if (typeof result === 'string') {
      return JSON.parse(result) as ApiResponse<T>;
    }
    if (result instanceof ArrayBuffer) {
      const text = String.fromCharCode(...new Uint8Array(result));
      return JSON.parse(text) as ApiResponse<T>;
    }
    return result as ApiResponse<T>;
  }

  private isSuccessResponse<T>(response: ApiResponse<T>): boolean {
    const raw = response as object as Record<string, Object>;
    return String(response.code) === '200' || String(response.code) === '0' || raw['success'] === true;
  }

  private buildUploadHeaders(): Record<string, string> {
    const headers: Record<string, string> = {};
    if (this.accessToken) {
      headers.Authorization = `Bearer ${this.accessToken}`;
    }
    return headers;
  }
}

export const httpClient = new HttpClient();
