import { BaseRequest, httpClient, JsonBody, QueryParams } from './httpClient';

export interface SortDTO {
  field: string;
  direction: string;
}

export interface FilterTimeDTO {
  field?: string;
  startTime?: string;
  endTime?: string;
}

export interface BaseListDTO {
  sort?: SortDTO;
  filterTime?: FilterTimeDTO;
}

export interface PageQueryDTO<T> {
  pageNum?: number;
  pageSize?: number;
  params?: T;
}

export interface PageResponse<T> {
  records: T[];
  total: number;
  size: number;
  current: number;
  pages: number;
}

export interface LogOperationDTO extends BaseListDTO {
  name?: string;
  module?: string;
  description?: string;
  code?: number;
  type?: string;
  method?: string;
}

export interface LogOperationVO {
  id: number;
  userId?: number;
  name?: string;
  module: string;
  description?: string;
  type: string;
  method: string;
  code: number;
  url: string;
  ip: string;
  requestParam?: string;
  responseParam?: string;
  errorMessage?: string;
  operateTime: number;
  createTime: string;
}

export interface LogLoginDTO extends BaseListDTO {
  browser?: string;
  operatingSystem?: string;
  type?: string;
  status?: string;
  name?: string;
}

export interface LogLoginVO {
  id: number;
  name?: string;
  ip?: string;
  browser: string;
  operatingSystem: string;
  deviceModel: string;
  type: string;
  status: string;
  errorMessage?: string;
  operateTime: number;
  createTime: string;
}

class LogApi {
  getLogOperationList(request: PageQueryDTO<LogOperationDTO>): Promise<PageResponse<LogOperationVO>> {
    const options: BaseRequest = { data: JsonBody.from(request) };
    return httpClient.post<PageResponse<LogOperationVO>>('/log/operation/list', options);
  }

  getLogOperation(id: number): Promise<LogOperationVO> {
    return httpClient.get<LogOperationVO>('/log/operation/get', {
      params: new QueryParams().put('id', id)
    });
  }

  getLogLoginList(request: PageQueryDTO<LogLoginDTO>): Promise<PageResponse<LogLoginVO>> {
    const options: BaseRequest = { data: JsonBody.from(request) };
    return httpClient.post<PageResponse<LogLoginVO>>('/log/login/list', options);
  }
}

export const logApi = new LogApi();
