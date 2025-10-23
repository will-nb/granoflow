# Monetization Architecture

## 目标
- 支持离线优先的订阅体验：可在离线状态下记录试用与计数，联网后触发付费提醒。
- 提供统一的 API 供 UI 查询当前付费状态并触发试用、订阅、取消等操作。

## 组件划分
| 组件 | 职责 |
| --- | --- |
| `MonetizationService` | 管理试用、订阅、配额计数，提供 `watch()` 流。 |
| `MonetizationActionsNotifier` | Riverpod 封装，暴露 startTrial/activate/cancel 操作。 |
| `TimerPage` | 在启动计时器时调用 `registerPremiumHit()`，根据 `shouldShowPaywall()` 决定是否弹窗。 |
| Paywall Widget | TODO：集成第三方支付 SDK 或平台内购，依赖于当前付费状态。 |

## 状态机
```
FREE -> startTrial() -> TRIAL_ACTIVE -> trialExpired -> LIMITED
LIMITED + activateSubscription() -> SUBSCRIBED
SUBSCRIBED + cancelSubscription() -> LIMITED
```

- `sessionsRemaining` 在 FREE/LIMITED 状态下降至 0 时触发付费提示。
- 订阅成功后直接进入 `SUBSCRIBED` 状态，不受配额限制。

## 数据持久化
- 当前阶段使用内存状态，未来可扩展至 PreferenceRepository 或后端同步。
- 需要持久化的字段：trialStart、trialEndsAt、isSubscribed、sessionsRemaining。

## 集成点
- 计时页面：开始专注时调用 `registerPremiumHit()` 并依据 `shouldShowPaywall()` 决定是否展示试用/订阅提示。
- 首页：根据付费状态展示 Banner（待实现）。
- Monetization paywall：基于状态显示不同 CTA（开始试用、续订、恢复购买）。

## 后续计划
1. 对接平台内购（StoreKit / Google Play Billing），将订阅状态持久化。
2. 在 `MonetizationService` 中引入仓库层，支持离线恢复购买记录。
3. 将付费事件上报到指标系统，用于计算付费转化率与试用表现。
