import { common } from '@kit.AbilityKit';
import { authApi, JwtVO } from '../services/api/auth';
import { httpClient } from '../services/api/httpClient';
import { AuthSnapshot, AuthStorage } from './authStorage';

export class AuthStore {
  private static instance: AuthStore | null = null;
  private storage: AuthStorage | null = null;
  private initPromise: Promise<void> = Promise.resolve();

  static getInstance(): AuthStore {
    if (AuthStore.instance === null) {
      AuthStore.instance = new AuthStore();
      AuthStore.instance.bootstrapRefreshHandler();
    }
    return AuthStore.instance;
  }

  init(context: common.UIAbilityContext): void {
    this.initPromise = this.bootstrapStorage(context);
  }

  private bootstrapRefreshHandler(): void {
    httpClient.setRefreshHandler(async () => this.refreshAuth());
  }

  private async bootstrapStorage(context: common.UIAbilityContext): Promise<void> {
    this.storage = await AuthStorage.create(context);
    const snapshot = await this.storage.read();
    this.applyAuth(snapshot);
  }

  async login(username: string, password: string): Promise<void> {
    await this.initPromise;
    const jwt = await authApi.login(username, password);
    await this.setAuth(jwt);
  }

  async refreshAuth(): Promise<boolean> {
    await this.initPromise;
    const refreshToken = AppStorage.get('refreshToken') as string || '';
    if (!refreshToken) {
      await this.clearAuth();
      return false;
    }

    try {
      const jwt = await authApi.refresh(refreshToken);
      await this.setAuth(jwt);
      return true;
    } catch (e) {
      void e;
      await this.clearAuth();
      return false;
    }
  }

  async logout(showSuccess?: boolean): Promise<void> {
    await this.initPromise;
    const refreshToken = AppStorage.get('refreshToken') as string || '';
    try {
      if (refreshToken) {
        await authApi.logout(refreshToken, showSuccess);
      }
    } catch (e) {
      void e;
    } finally {
      await this.clearAuth();
    }
  }

  private async setAuth(jwt: JwtVO): Promise<void> {
    const snapshot: AuthSnapshot = {
      accessToken: jwt.accessToken,
      refreshToken: jwt.refreshToken,
      username: jwt.username
    };
    this.applyAuth(snapshot);
    if (this.storage !== null) {
      await this.storage.save(snapshot);
    }
  }

  async clearAuth(): Promise<void> {
    AppStorage.setOrCreate('accessToken', '');
    AppStorage.setOrCreate('refreshToken', '');
    AppStorage.setOrCreate('username', '');
    httpClient.clearAccessToken();
    if (this.storage !== null) {
      await this.storage.clear();
    }
  }

  private applyAuth(snapshot: AuthSnapshot): void {
    AppStorage.setOrCreate('accessToken', snapshot.accessToken);
    AppStorage.setOrCreate('refreshToken', snapshot.refreshToken);
    AppStorage.setOrCreate('username', snapshot.username);
    httpClient.setAccessToken(snapshot.accessToken);
  }

  get isLoggedIn(): boolean {
    return !!(AppStorage.get('accessToken') as string);
  }
}
