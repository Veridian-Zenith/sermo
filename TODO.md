# Sermo — Production Readiness Roadmap

## Phase 1: Test Coverage — Contexts
- [x] Accounts context (`register_user`, `get_user`, `authenticate`, `update_user`, `change_password`)
- [x] Conversations context (DM/group CRUD, messages, membership, enrichment)
- [ ] Friendships module (`send_friend_request`, accept/decline/cancel/remove, `friend_status`, `list_friends`)
- [ ] Recovery keys module (`generate_recovery_keys`, `verify_recovery_key`, `recover_account`)
- [ ] API registration controller
- [ ] API session controller (login, logout, token validation)

## Phase 2: Test Coverage — Controllers & Plugs
- [ ] Session controller (login/logout)
- [ ] Registration controller
- [ ] Page controller
- [ ] Recovery download controller
- [ ] `RequireAuth` plug
- [ ] `UserAuth` plug
- [ ] `RateLimit` plug
- [ ] `SecurityHeaders` plug
- [ ] API auth plug

## Phase 3: Test Coverage — LiveViews
- [ ] `LoginLive`
- [ ] `RegisterLive`
- [ ] `ChatLive`
- [ ] `NewConversationLive`
- [ ] `ProfileLive`
- [ ] `FriendsLive`
- [ ] `RecoverLive`
- [ ] `RecoveryKeysLive`

## Phase 4: Production Hardening
- [ ] Proper Swoosh adapter configuration for prod
- [ ] Structured logging / log levels
- [ ] Telemetry metrics & dashboard configuration
- [ ] Graceful error pages for all formats
- [ ] Handle disconnects/reconnects gracefully in LiveView
- [ ] Rate limit tuning (configurable thresholds)
- [ ] CORS configuration for API
- [ ] Database connection pooling tuning

## Phase 5: Messaging Features
- [ ] File/image attachments in messages
- [ ] Message search
- [ ] Message reactions
- [ ] Read receipts
- [ ] Message reply/thread support

## Phase 6: Notifications
- [ ] Push notification support (Web Push API)
- [ ] In-app notification bell/badge
- [ ] Email notifications for offline mentions

## Phase 7: Admin & Moderation
- [ ] Admin panel (user management, conversations overview)
- [ ] Message reporting
- [ ] User blocking
- [ ] Content moderation tools

## Phase 8: UI Polish
- [ ] Responsive design / mobile-friendly layout
- [ ] Loading states & skeleton screens
- [ ] Emoji picker
- [ ] Keyboard shortcuts
- [ ] Accessibility improvements
- [ ] Dark/light theme toggle
