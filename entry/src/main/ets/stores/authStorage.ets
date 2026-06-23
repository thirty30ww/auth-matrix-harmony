import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

const STORE_NAME = 'auth';
const ACCESS_TOKEN = 'accessToken';
const REFRESH_TOKEN = 'refreshToken';
const USERNAME = 'username';

export interface AuthSnapshot {
  accessToken: string;
  refreshToken: string;
  username: string;
}

export class AuthStorage {
  private preferences: preferences.Preferences;

  private constructor(pref: preferences.Preferences) {
    this.preferences = pref;
  }

  static async create(context: common.UIAbilityContext): Promise<AuthStorage> {
    const pref = await preferences.getPreferences(context, STORE_NAME);
    return new AuthStorage(pref);
  }

  async read(): Promise<AuthSnapshot> {
    return {
      accessToken: await this.preferences.get(ACCESS_TOKEN, '') as string,
      refreshToken: await this.preferences.get(REFRESH_TOKEN, '') as string,
      username: await this.preferences.get(USERNAME, '') as string
    };
  }

  async save(auth: AuthSnapshot): Promise<void> {
    await this.preferences.put(ACCESS_TOKEN, auth.accessToken);
    await this.preferences.put(REFRESH_TOKEN, auth.refreshToken);
    await this.preferences.put(USERNAME, auth.username);
    await this.preferences.flush();
  }

  async clear(): Promise<void> {
    await this.preferences.delete(ACCESS_TOKEN);
    await this.preferences.delete(REFRESH_TOKEN);
    await this.preferences.delete(USERNAME);
    await this.preferences.flush();
  }
}
