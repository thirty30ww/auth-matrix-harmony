import { httpClient } from './httpClient';

class FileApi {
  uploadImage(fileUri: string): Promise<string> {
    return httpClient.uploadFile<string>('/file/upload/image', fileUri, 'file');
  }
}

export const fileApi = new FileApi();
