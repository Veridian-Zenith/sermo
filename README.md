# Sermo

A real-time messaging and chat platform built with Phoenix LiveView. Name derived from Latin for "conversation" or "talk."

## Features

- **Direct & group conversations** — one-on-one or multi-user chats
- **Real-time messaging** — messages appear instantly via WebSockets
- **Online presence** — see who's online via Phoenix Presence
- **Live typing indicators** — see when someone is composing a message
- **Friend system** — send/accept/decline/cancel friend requests, manage friends
- **User profiles** — display name, bio, avatar upload, social links
- **Account recovery** — encrypted one-time recovery keys (ChaCha20-Poly1305) for password resets
- **Session-based auth** — browser cookie sessions with Argon2id password hashing
- **JSON REST API** — programmatic access with token-based authentication
- **Rate limiting** — ETS-based in-process rate limiter on auth endpoints
- **Security headers** — CSP, X-Frame-Options, X-Content-Type-Options, etc.
- **Dark theme** — orange/red gradient color scheme with custom Rosemary font
- **Telemetry** — Phoenix and Ecto query metrics via LiveDashboard
- **No external services** — fully self-contained, no Redis, no cloud dependencies

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Framework | Phoenix 1.8.8 |
| Language | Elixir ~> 1.15 |
| HTTP Server | Bandit 1.5 |
| Database | PostgreSQL 16 (via Ecto) |
| Password Hashing | Argon2id (via argon2_elixir) |
| Encryption | ChaCha20-Poly1305 (via :crypto, BEAM built-in) |
| Real-time | Phoenix LiveView + PubSub (PG2, no external broker) |
| Presence | Phoenix Presence |
| Mailer | Swoosh (local adapter by default) |
| HTTP Client | Req 0.5 |
| JSON | Jason |
| I18n | Gettext |
| Metrics | Telemetry + LiveDashboard |
| CSS | All inline (no framework), dark theme |
| Font | Rosemary (bundled TTF) |

## Getting Started

```bash
# Clone the repo
git clone <repo-url> && cd sermo

# Install dependencies and set up the database
mix setup

# Start the Phoenix server
mix phx.server

# Visit http://localhost:4000
```

### Setup commands

| Command | Action |
|---------|--------|
| `mix setup` | Install deps, create DB, run migrations, seed data |
| `mix phx.server` | Start the dev server |
| `iex -S mix phx.server` | Start with interactive IEx shell |
| `mix test` | Run the test suite |
| `mix precommit` | Compile with warnings as errors, check unused deps, format, test |

## Architecture

### Supervision Tree (`lib/sermo/application.ex`)

```
Sermo.Supervisor (one_for_one)
├── SermoWeb.Telemetry
├── Sermo.Repo (Ecto, PostgreSQL)
├── DNSCluster
├── Phoenix.PubSub (Sermo.PubSub, PG2)
├── SermoWeb.Presence
└── SermoWeb.Endpoint
```

### Domain Contexts

#### `Sermo.Accounts` — User & Friend Management

| Function | Description |
|----------|-------------|
| `register_user/1` | Create a new user (Argon2id hashing) |
| `get_user/1` | Fetch user by ID |
| `get_user_by_username/1` | Fetch user by username |
| `list_other_users/2` | List all users except current user (paginated) |
| `authenticate/2` | Verify username + password |
| `update_user/2` | Update profile (display name, bio, avatar, links) |
| `change_password/2` | Change user password |
| `generate_recovery_keys/2` | Create N encrypted recovery keys |
| `list_recovery_keys/1` | List recovery keys with usage status |
| `recover_account/3` | Reset password using a recovery key |
| `has_recovery_keys?/1` | Check if user has unused recovery keys |
| `send_friend_request/2` | Send a friend request |
| `accept_friend_request/2` | Accept an incoming request |
| `decline_friend_request/2` | Decline an incoming request |
| `cancel_friend_request/2` | Cancel an outgoing request |
| `remove_friend/2` | Remove a friend |
| `list_friends/1` | List accepted friends |
| `list_incoming_requests/1` | List pending requests received |
| `list_outgoing_requests/1` | List pending requests sent |
| `friend_status/2` | Get relationship status between two users |

#### `Sermo.Conversations` — Messaging

| Function | Description |
|----------|-------------|
| `create_direct_conversation/2` | Create or find existing DM |
| `create_group_conversation/3` | Create a group conversation |
| `get_conversation/1` | Get conversation with members preloaded |
| `list_conversations/1` | List user's conversations (by updated_at desc) |
| `list_members/1` | List conversation members |
| `is_member?/2` | Check if user is a member |
| `add_members/2` | Add users to a group |
| `remove_member/2` | Remove a user from a conversation |
| `delete_conversation/1` | Delete conversation (cascade messages + members) |
| `send_message/3` | Send a message (broadcasts via PubSub) |
| `update_message/3` | Edit a message (sender only) |
| `delete_message/2` | Delete a message (sender only) |
| `list_messages/2` | List messages (newest last, default 50) |
| `last_message/1` | Get the most recent message |
| `enrich_conversations/2` | Set virtual `display_name` based on conversation type |

#### `Sermo.Crypto` — Encryption Utilities

| Function | Description |
|----------|-------------|
| `encrypt/1` | ChaCha20-Poly1305 encrypt → base64 |
| `decrypt/1` | Decrypt base64 → `{:ok, plain}` or `:error` |
| `random_token/1` | Generate hex-encoded random token |
| `generate_recovery_key/0` | Generate formatted recovery key (`xxxx-xxxx-xxxx-xxxx`) |
| `blake2b/1` | BLAKE2b-256 hash |

### Database Schema

#### `users`

| Column | Type | Constraints |
|--------|------|-------------|
| id | binary_id | PK, auto-generated |
| username | string | Unique, alphanumeric, 2-32 chars |
| password_hash | string | Argon2id hash |
| display_name | string | Optional, max 64 chars |
| avatar_path | string | Optional, file path in `priv/static/uploads/avatars/` |
| bio | string | Optional, max 500 chars |
| social_links | map | JSON map of label→URL pairs |
| inserted_at | utc_datetime | |
| updated_at | utc_datetime | |

#### `friendships`

| Column | Type | Constraints |
|--------|------|-------------|
| id | binary_id | PK |
| requester_id | binary_id | FK → users |
| requested_id | binary_id | FK → users |
| status | string | "pending", "accepted", or "declined" |
| inserted_at | utc_datetime | |
| updated_at | utc_datetime | |
| | | UNIQUE(requester_id, requested_id) |

#### `user_recovery_keys`

| Column | Type | Constraints |
|--------|------|-------------|
| id | binary_id | PK |
| user_id | binary_id | FK → users |
| key_ciphertext | text | ChaCha20-Poly1305 encrypted, base64 |
| used_at | utc_datetime | Nullable, set when consumed |
| inserted_at | utc_datetime | |
| updated_at | utc_datetime | |

#### `conversations`

| Column | Type | Constraints |
|--------|------|-------------|
| id | binary_id | PK |
| name | string | Optional, group name |
| type | string | "direct" or "group" |
| created_by_id | binary_id | FK → users |
| inserted_at | utc_datetime | |
| updated_at | utc_datetime | |
| display_name | string | Virtual field, computed at runtime |

#### `conversation_members`

| Column | Type | Constraints |
|--------|------|-------------|
| id | binary_id | PK |
| user_id | binary_id | FK → users |
| conversation_id | binary_id | FK → conversations |
| role | string | "admin" or "member" |
| inserted_at | utc_datetime | |
| updated_at | utc_datetime | |
| | | UNIQUE(user_id, conversation_id) |

#### `messages`

| Column | Type | Constraints |
|--------|------|-------------|
| id | binary_id | PK |
| body | text | 1-4096 chars |
| conversation_id | binary_id | FK → conversations |
| sender_id | binary_id | FK → users |
| inserted_at | utc_datetime | |
| updated_at | utc_datetime | |

## Routes

### Browser (HTML)

| Method | Path | Handler | Auth Required |
|--------|------|---------|---------------|
| GET | `/` | PageController.index | No (redirects to /chat if logged in) |
| GET | `/login` | LoginLive | No |
| GET | `/register` | RegisterLive | No |
| GET | `/recover` | RecoverLive | No |
| POST | `/session` | SessionController.create | No (rate-limited) |
| POST | `/register` | RegistrationController.create | No (rate-limited) |
| GET | `/logout` | SessionController.delete | Yes |
| GET | `/chat` | ChatLive | Yes |
| GET | `/conversations/new` | NewConversationLive | Yes |
| GET | `/profile` | ProfileLive | Yes |
| GET | `/friends` | FriendsLive | Yes |
| GET | `/recovery-keys` | RecoveryKeysLive | Yes |
| GET | `/recovery-keys/download` | RecoveryDownloadController.download | Yes |

### API (JSON)

| Method | Path | Handler | Auth Required |
|--------|------|---------|---------------|
| POST | `/api/v1/register` | API.RegistrationController.create | No |
| POST | `/api/v1/session` | API.SessionController.create | No |
| DELETE | `/api/v1/session` | API.SessionController.delete | No |

### Dev Only

| Path | Handler |
|------|---------|
| `/dev/dashboard` | Phoenix LiveDashboard |
| `/dev/mailbox` | Swoosh Mailbox Preview |

## Real-time Architecture

Real-time features use Phoenix PubSub (PG2-based, no external broker):

- **Messages**: Messages are broadcast to all conversation members via `user:<id>` topics
- **Typing**: Typing indicators broadcast on keystroke, auto-clear after 3 seconds
- **Presence**: Online/offline tracking via `SermoWeb.Presence` (Phoenix.Presence)
- **Conversation updates**: New/updated conversations broadcast to all members

## Authentication

### Browser (Session-based)
- Sessions stored in signed cookies (`_sermo_key`)
- `UserAuth` plug loads `current_user` from session
- `RequireAuth` plug redirects unauthenticated users to `/login`

### API (Token-based)
- Bearer token authentication via `Authorization` header
- Tokens are `Phoenix.Token` signed tokens, valid for 30 days
- `API.Auth` plug loads `api_user`; `require_auth/2` returns 401 if missing

## Account Recovery Flow

1. User requests recovery at `/recover`
2. Enters username → system checks for unused recovery keys
3. User enters recovery key (format: `xxxx-xxxx-xxxx-xxxx`)
4. System decrypts stored key and compares
5. User sets a new password
6. Recovery key is marked as used (one-time use)

## Rate Limiting

- ETS-based sliding window (60-second window)
- Applied to POST `/session` and POST `/register`
- Default limit: 20 requests per window per IP
- Configurable via `max` option or `:sermo, SermoWeb.Plugs.RateLimit` config
- Returns 429 with `Retry-After` header when exceeded

## Configuration

### Environment Variables (production)

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | Yes | Ecto connection string |
| `SECRET_KEY_BASE` | Yes | Phoenix signing/encryption secret |
| `RECOVERY_ENCRYPTION_KEY` | Yes | 32-byte base64-encoded ChaCha20 key |
| `PHX_HOST` | Yes | Public hostname |
| `PORT` | No | HTTP port (default 4000) |
| `POOL_SIZE` | No | DB pool size (default 2) |

### Generating Secrets

```bash
mix phx.gen.secret                                    # SECRET_KEY_BASE
mix run -e 'IO.puts(:crypto.strong_rand_bytes(32) |> Base.encode64())'  # RECOVERY_ENCRYPTION_KEY
```

## Development

```bash
# Dev server (auto-reloads)
mix phx.server

# Interactive console
iex -S mix phx.server
```

### Defaults

- Database: `localhost/sermo_dev`, user `postgres`, no password
- Server: `http://localhost:4000`
- Rate limit: max 100 requests/window (dev)
- Mailer: Local (preview at `/dev/mailbox`)

## Deployment

See [DEPLOY.md](DEPLOY.md) for deployment instructions.

## Production Roadmap

See [TODO.md](TODO.md) for planned enhancements including:
- Full test coverage
- Push notifications (Web Push API)
- File/image attachments
- Message search, reactions, threads
- Admin panel and moderation tools
- Responsive mobile design
- Accessibility improvements
