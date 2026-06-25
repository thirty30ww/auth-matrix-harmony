import { router } from '@kit.ArkUI'
import { AuthStore } from '../stores/authStore'
import { ProfileTab } from './Profile'
import { OperationLogTab } from './OperationLog'
import { LoginLogTab } from './LoginLog'

const authStore = AuthStore.getInstance()

@Entry
@Component
struct TabHome {
  @State currentIndex: number = 0
  @StorageLink('accessToken') @Watch('onAccessTokenChange') accessToken: string = ''

  private activeIcons: Resource[] = [
    $r('app.media.ic_user_active'),
    $r('app.media.ic_list_active'),
    $r('app.media.ic_clock_active')
  ]
  private inactiveIcons: Resource[] = [
    $r('app.media.ic_user'),
    $r('app.media.ic_list'),
    $r('app.media.ic_clock')
  ]
  private labels: ResourceStr[] = ['个人主页', '操作日志', '登录日志']

  async aboutToAppear(): Promise<void> {
    await authStore.waitForInit()

    if (!this.accessToken) {
      router.replaceUrl({ url: 'pages/Login' })
    }
  }

  private onAccessTokenChange(): void {
    if (!this.accessToken) {
      router.replaceUrl({ url: 'pages/Login' })
    }
  }

  @Builder
  private tabBuilder(index: number) {
    Column() {
      Image(this.currentIndex === index ? this.activeIcons[index] : this.inactiveIcons[index])
        .width(22)
        .height(22)
      Text(this.labels[index])
        .fontSize(11)
        .fontColor(this.currentIndex === index ? $r('app.color.app_primary') : $r('app.color.app_text_secondary'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
      TabContent() {
        ProfileTab()
      }
      .tabBar(this.tabBuilder(0))

      TabContent() {
        OperationLogTab()
      }
      .tabBar(this.tabBuilder(1))

      TabContent() {
        LoginLogTab()
      }
      .tabBar(this.tabBuilder(2))
    }
    .onChange((index: number) => {
      this.currentIndex = index
    })
    .barHeight(56)
    .backgroundColor($r('app.color.app_card_bg'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .width('100%')
    .height('100%')
  }
}
