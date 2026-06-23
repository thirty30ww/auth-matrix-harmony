import { promptAction, router } from '@kit.ArkUI'
import { Role, userApi, UserVO } from '../services/api/user'
import { AuthStore } from '../stores/authStore'

const authStore = AuthStore.getInstance()

@Entry
@Component
struct Profile {
  @State user: UserVO | null = null
  @State loading: boolean = false
  @State errorText: string = ''
  @State routeToastKey: string = ''
  @State pendingToastKey: string = ''
  @StorageLink('profileRefreshVersion') @Watch('onProfileRefresh') profileRefreshVersion: number = 0

  aboutToAppear(): void {
    this.loadUser()
  }

  onPageShow(): void {
    this.showRouteToast()
    this.loadUser()
  }

  private onProfileRefresh(): void {
    this.loadUser()
  }

  private async loadUser(): Promise<void> {
    if (this.loading) {
      return
    }
    this.loading = true
    this.errorText = ''
    try {
      const user = await userApi.getUser()
      this.user = user
    } catch (e) {
      const err = e as Error
      this.errorText = err.message || '获取用户信息失败'
    } finally {
      this.loading = false
    }
  }

  private async logout(): Promise<void> {
    try {
      await authStore.logout()
      promptAction.showToast({ message: '已退出登录' })
      router.replaceUrl({ url: 'pages/Login' })
    } catch (e) {
      const err = e as Error
      promptAction.showToast({ message: err.message || '退出登录失败' })
    }
  }

  private showRouteToast(): void {
    const rawParams = router.getParams()
    if (rawParams === null || rawParams === undefined) {
      return
    }

    const params = rawParams as object as Record<string, string>
    const message = params['toastMessage'] || ''
    const key = params['toastKey'] || ''
    if (!message || !key || key === this.routeToastKey || key === this.pendingToastKey) {
      return
    }

    this.pendingToastKey = key
    setTimeout(() => {
      try {
        this.getUIContext().getPromptAction().showToast({ message })
        this.routeToastKey = key
      } catch (e) {
        try {
          promptAction.showToast({ message })
          this.routeToastKey = key
        } catch (fallbackError) {
          void e
          void fallbackError
        }
      } finally {
        if (this.pendingToastKey === key) {
          this.pendingToastKey = ''
        }
      }
    }, 100)
  }

  private getRoleNames(): string {
    if (this.user === null || !this.user.roles || this.user.roles.length === 0) {
      return '-'
    }
    const names: string[] = []
    this.user.roles.forEach((role: Role) => {
      names.push(role.name)
    })
    return names.join('、')
  }

  private getAvatarText(): string {
    if (this.user === null) {
      return 'U'
    }
    const text = this.user.name || this.user.username || 'U'
    return text.substring(0, 1)
  }

  private hasAvatar(): boolean {
    return this.user !== null && !!this.user.avatarUrl
  }

  private getAvatarUrl(): string {
    if (this.user === null) {
      return ''
    }
    return this.user.avatarUrl || ''
  }

  private getUserName(): string {
    if (this.user === null) {
      return '-'
    }
    return this.user.name || '-'
  }

  private getSignature(): string {
    if (this.user === null) {
      return '这个人很懒，什么都没留下...'
    }
    return this.user.signature || '这个人很懒，什么都没留下...'
  }

  private getUsername(): string {
    if (this.user === null) {
      return ''
    }
    return this.user.username || ''
  }

  private getSex(): string {
    if (this.user === null) {
      return ''
    }
    return this.user.sex || ''
  }

  private getCreateTime(): string {
    if (this.user === null) {
      return ''
    }
    return this.user.createTime || ''
  }

  @Builder
  private InfoRow(icon: Resource, label: string, value: string): void {
    Row({ space: 12 }) {
      Stack() {
        Image(icon)
          .width(18)
          .height(18)
      }
      .width(28)
      .height(28)
      .borderRadius(8)
      .backgroundColor('#F3EEFF')

      Column({ space: 2 }) {
        Text(label)
          .fontSize(12)
          .fontColor($r('app.color.app_text_secondary'))

        Text(value || '-')
          .fontSize(15)
          .fontColor($r('app.color.app_text_primary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 9, bottom: 9 })
  }

  @Builder
  private AvatarView(size: number): void {
    if (this.hasAvatar()) {
      Image(this.getAvatarUrl())
        .width(size)
        .height(size)
        .borderRadius(size / 2)
        .objectFit(ImageFit.Cover)
        .border({ width: 4, color: '#B99EFF' })
    } else {
      Stack() {
        Text(this.getAvatarText())
          .fontSize(34)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.app_primary'))
      }
      .width(size)
      .height(size)
      .borderRadius(size / 2)
      .backgroundColor(Color.White)
      .border({ width: 4, color: '#B99EFF' })
    }
  }

  @Builder
  private HeaderHero(): void {
    Stack({ alignContent: Alignment.Top }) {
      Stack() {
      }
      .height(260)
      .width('100%')
      .backgroundColor($r('app.color.app_primary'))
      .borderRadius({ bottomLeft: 32, bottomRight: 32 })
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      Column({ space: 8 }) {
        this.AvatarView(96)

        Text(this.getUserName())
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })

        Text(this.getSignature())
          .fontSize(13)
          .fontColor('#F1EAFF')
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .width('100%')
      .padding({ left: 34, right: 34, top: 42 })
    }
    .height(260)
    .width('100%')
  }

  @Builder
  private ProfileInfo(): void {
    Column({ space: 2 }) {
      this.InfoRow($r('app.media.ic_user_active'), '用户名', this.getUsername())
      this.InfoRow($r('app.media.ic_gender'), '性别', this.getSex())
      this.InfoRow($r('app.media.ic_calendar'), '创建时间', this.getCreateTime())
      this.InfoRow($r('app.media.ic_badge'), '角色', this.getRoleNames())
    }
    .padding({ left: 18, right: 18, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.app_card_bg'))
    .borderRadius(12)
    .width('100%')
  }

  @Builder
  private BottomNav(): void {
    Column() {
      Row() {
        this.TabItem($r('app.media.ic_user_active'), '个人主页', 'pages/Profile', true)
        this.TabItem($r('app.media.ic_list'), '操作日志', 'pages/OperationLog', false)
        this.TabItem($r('app.media.ic_clock'), '登录日志', 'pages/LoginLog', false)
      }
      .height(56)
      .width('100%')
    }
    .width('100%')
    .backgroundColor($r('app.color.app_card_bg'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }

  @Builder
  private ActionItem(icon: Resource, title: string, description: string, url: string): void {
    Row({ space: 12 }) {
      Stack() {
        Image(icon)
          .width(18)
          .height(18)
      }
      .width(28)
      .height(28)
      .borderRadius(8)
      .backgroundColor('#F3EEFF')

      Column({ space: 2 }) {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.app_text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(description)
          .fontSize(12)
          .fontColor($r('app.color.app_text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('>')
        .fontSize(16)
        .fontColor($r('app.color.app_text_secondary'))
    }
    .height(58)
    .width('100%')
    .onClick(() => {
      router.pushUrl({ url })
    })
  }

  @Builder
  private ActionCard(): void {
    Column() {
      this.ActionItem($r('app.media.ic_edit'), '编辑个人信息', '修改姓名、性别和个性签名', 'pages/EditProfile')

      Stack() {
      }
      .height(1)
      .width('100%')
      .backgroundColor($r('app.color.app_border'))

      this.ActionItem($r('app.media.ic_lock'), '修改密码', '定期更新密码以保护账号安全', 'pages/ChangePassword')
    }
    .padding({ left: 18, right: 18, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.app_card_bg'))
    .borderRadius(12)
    .width('100%')
  }

  @Builder
  private ActionCardBlock(): void {
    Column() {
      this.ActionCard()
    }
    .width('100%')
    .margin({ top: 18 })
  }

  @Builder
  private LogoutButton(): void {
    Button('退出登录')
      .height(46)
      .width('100%')
      .fontSize(15)
      .fontColor(Color.White)
      .backgroundColor($r('app.color.app_danger'))
      .borderRadius(12)
      .onClick(() => {
        this.logout()
      })
  }

  @Builder
  private LogoutButtonBlock(): void {
    Column() {
      this.LogoutButton()
    }
    .width('100%')
    .margin({ top: 18 })
  }

  @Builder
  private TabItem(icon: Resource, title: string, url: string, active: boolean): void {
    Column({ space: 3 }) {
      Stack() {
        Image(icon)
          .width(20)
          .height(20)
      }
      .width(24)
      .height(24)

      Text(title)
        .fontSize(12)
        .fontWeight(active ? FontWeight.Bold : FontWeight.Regular)
        .fontColor(active ? $r('app.color.app_primary') : $r('app.color.app_text_secondary'))
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (!active) {
        router.replaceUrl({ url })
      }
    })
  }

  build() {
    Column() {
      this.HeaderHero()

      Scroll() {
        Column() {
          if (this.errorText) {
            Text(this.errorText)
              .height(18)
              .fontSize(12)
              .fontColor($r('app.color.app_danger'))
              .width('100%')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ bottom: 18 })
          }

          if (this.loading && this.user === null) {
            Text('加载用户信息中...')
              .fontSize(14)
              .fontColor($r('app.color.app_text_secondary'))
              .width('100%')
              .padding(18)
          } else {
            this.ProfileInfo()
            this.ActionCardBlock()
            this.LogoutButtonBlock()
          }
        }
        .padding({ left: 14, right: 14, top: 0, bottom: 10 })
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor($r('app.color.app_bg'))
      .margin({ top: -15 })

      this.BottomNav()
    }
    .backgroundColor($r('app.color.app_bg'))
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }
}
