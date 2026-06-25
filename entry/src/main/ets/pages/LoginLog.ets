import { promptAction, router } from '@kit.ArkUI'
import { LogLoginDTO, LogLoginVO, logApi, PageQueryDTO } from '../services/api/log'

@Entry
@Component
struct LoginLog {
  @State logs: LogLoginVO[] = []
  @State keyword: string = ''
  @State pageNum: number = 1
  @State pageSize: number = 10
  @State total: number = 0
  @State pages: number = 0
  @State hasMore: boolean = true
  @State loading: boolean = false
  @State errorText: string = ''

  aboutToAppear(): void {
    this.loadLogs()
  }

  private async loadLogs(resetPage?: boolean, targetPage?: number): Promise<void> {
    if (this.loading) {
      return
    }
    if (!resetPage && !this.hasMore && this.logs.length > 0) {
      return
    }
    const nextPage = resetPage ? 1 : (targetPage || this.pageNum)
    if (resetPage) {
      this.pageNum = 1
      this.logs = []
      this.hasMore = true
    }
    this.loading = true
    this.errorText = ''
    try {
      const params: LogLoginDTO = {
        name: this.keyword || undefined,
        sort: {
          field: 'createTime',
          direction: 'desc'
        }
      }
      const request: PageQueryDTO<LogLoginDTO> = {
        pageNum: nextPage,
        pageSize: this.pageSize,
        params
      }
      const response = await logApi.getLogLoginList(request)
      const records = response.records || []
      this.logs = nextPage === 1 ? records : this.logs.concat(records)
      this.pageNum = response.current
      this.pageSize = response.size
      this.total = response.total
      this.pages = response.pages
      this.hasMore = this.pageNum < this.pages
    } catch (e) {
      const err = e as Error
      this.errorText = err.message || '获取登录日志失败'
      promptAction.showToast({ message: this.errorText })
    } finally {
      this.loading = false
    }
  }

  private loadMore(): void {
    if (!this.hasMore || this.loading) {
      return
    }
    this.loadLogs(false, this.pageNum + 1)
  }

  private statusColor(status: string): ResourceColor {
    if (status === '成功' || status === 'SUCCESS') {
      return '#23A55A'
    }
    if (status === '失败' || status === 'FAILED') {
      return $r('app.color.app_danger')
    }
    return $r('app.color.app_primary')
  }

  private statusIcon(status: string): Resource {
    if (status === '成功' || status === 'SUCCESS') {
      return $r('app.media.ic_status_success')
    }
    if (status === '失败' || status === 'FAILED') {
      return $r('app.media.ic_status_danger')
    }
    return $r('app.media.ic_status')
  }

  @Builder
  private Meta(icon: Resource, label: string, value: string): void {
    Row({ space: 8 }) {
      Image(icon)
        .width(15)
        .height(15)

      Text(label)
        .width(58)
        .fontSize(12)
        .fontColor($r('app.color.app_text_secondary'))

      Text(value || '-')
        .layoutWeight(1)
        .fontSize(13)
        .fontColor($r('app.color.app_text_primary'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
  }

  @Builder
  private LogCard(log: LogLoginVO): void {
    Column({ space: 9 }) {
      Row({ space: 8 }) {
        Text(log.name || '-')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.app_text_primary'))
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: 4 }) {
          Image(this.statusIcon(log.status))
            .width(14)
            .height(14)

          Text(log.status || '-')
            .fontSize(12)
            .fontColor(this.statusColor(log.status))
        }
      }
      .width('100%')

      Row({ space: 8 }) {
        Image($r('app.media.ic_terminal_active'))
          .width(14)
          .height(14)

        Text(log.type || '-')
          .fontSize(12)
          .fontColor($r('app.color.app_primary'))

        Image($r('app.media.ic_timer_active'))
          .width(14)
          .height(14)

        Text(`${log.operateTime}ms`)
          .fontSize(12)
          .fontColor($r('app.color.app_text_secondary'))
      }
      .width('100%')

      this.Meta($r('app.media.ic_network_active'), 'IP', log.ip || '-')
      this.Meta($r('app.media.ic_browser_active'), '浏览器', log.browser || '-')
      this.Meta($r('app.media.ic_monitor_active'), '操作系统', log.operatingSystem || '-')
      this.Meta($r('app.media.ic_server_active'), '设备', log.deviceModel || '-')
      this.Meta($r('app.media.ic_calendar'), '时间', log.createTime || '-')

      if (log.errorMessage) {
        Text(log.errorMessage)
          .fontSize(12)
          .fontColor($r('app.color.app_danger'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
    }
    .padding(16)
    .backgroundColor($r('app.color.app_card_bg'))
    .borderRadius(12)
    .width('100%')
  }

  @Builder
  private BottomNav(): void {
    Column() {
      Row() {
      this.TabItem($r('app.media.ic_user'), '个人主页', 'pages/Profile', false)
      this.TabItem($r('app.media.ic_list'), '操作日志', 'pages/OperationLog', false)
      this.TabItem($r('app.media.ic_clock_active'), '登录日志', 'pages/LoginLog', true)
      }
      .height(56)
      .width('100%')
    }
    .width('100%')
    .backgroundColor($r('app.color.app_card_bg'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
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
      Column() {
        Row({ space: 10 }) {
          TextInput({ text: this.keyword, placeholder: '搜索用户名' })
            .layoutWeight(1)
            .height(40)
            .fontSize(14)
            .backgroundColor($r('app.color.app_bg'))
            .fontColor($r('app.color.app_text_primary'))
            .placeholderColor($r('app.color.app_text_secondary'))
            .caretColor($r('app.color.app_primary'))
            .borderRadius(20)
            .onChange((next: string) => {
              this.keyword = next
            })

          Button() {
            Image($r('app.media.ic_search_light'))
              .width(18)
              .height(18)
          }
            .width(46)
            .height(40)
            .backgroundColor($r('app.color.app_primary'))
            .borderRadius(20)
            .onClick(() => {
              this.loadLogs(true)
            })

        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 44, bottom: 8 })
      }
      .width('100%')
      .backgroundColor($r('app.color.app_card_bg'))
      .borderRadius({ bottomLeft: 24, bottomRight: 24 })
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      Column({ space: 12 }) {
        if (this.errorText) {
          Text(this.errorText)
            .fontSize(12)
            .fontColor($r('app.color.app_danger'))
            .width('100%')
            .padding({ left: 14, right: 14 })
        }

        Scroll() {
          Column({ space: 16 }) {
            if (this.loading && this.logs.length === 0) {
              Text('加载登录日志中...')
                .fontSize(14)
                .fontColor($r('app.color.app_text_secondary'))
                .width('100%')
                .padding(18)
            } else if (this.logs.length === 0) {
              Text('暂无登录日志')
                .fontSize(14)
                .fontColor($r('app.color.app_text_secondary'))
                .width('100%')
                .padding(18)
            } else {
              ForEach(this.logs, (log: LogLoginVO) => {
                this.LogCard(log)
              }, (log: LogLoginVO) => String(log.id))

              if (this.loading) {
                Text('继续加载登录日志中...')
                  .fontSize(12)
                  .fontColor($r('app.color.app_text_secondary'))
                  .textAlign(TextAlign.Center)
                  .width('100%')
                  .padding({ top: 8, bottom: 10 })
              } else if (!this.hasMore) {
                Text(`已加载全部 ${this.total} 条登录日志`)
                  .fontSize(12)
                  .fontColor($r('app.color.app_text_secondary'))
                  .textAlign(TextAlign.Center)
                  .width('100%')
                  .padding({ top: 8, bottom: 10 })
              }
            }
          }
          .padding({ left: 14, right: 14, top: 14, bottom: 14 })
          .width('100%')
        }
        .onReachEnd(() => {
          this.loadMore()
        })
        .layoutWeight(1)
      }
      .layoutWeight(1)
      .backgroundColor($r('app.color.app_bg'))

      this.BottomNav()
    }
    .backgroundColor($r('app.color.app_bg'))
    .width('100%')
    .height('100%')
  }
}
