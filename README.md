# Handoff API

Rails 7.2 API and Sidekiq worker for **Handoff**, a fictional same-day delivery
company for local shops in Toronto. Handoff is a sample product used to demo
product workflows; this repo is its backend. The web apps live in
`handoff-apps`, the public site in `handoff-marketing`.

## Run it locally

Services run in Docker, Ruby runs on your machine.

```sh
docker compose up -d          # Postgres :5440, Redis :6390, Mailpit :8026 (SMTP :1026)
bundle install
bin/rails db:prepare db:seed  # creates, migrates, and seeds demo merchants and users
bin/rails server              # http://localhost:3200 (PORT comes from .env.development)
bundle exec sidekiq -C config/sidekiq.yml
```

Or with a Procfile runner: `foreman start -f Procfile.dev`.

- Sidekiq dashboard: http://localhost:3200/sidekiq
- Mail that the app sends: http://localhost:8026
- Health: http://localhost:3200/api/health

Demo sign-ins (password `handoff-demo` for all):

| Email | Role |
| --- | --- |
| maya@bloomandstem.example | Merchant admin, Bloom & Stem |
| sam@bloomandstem.example | Merchant staff, Bloom & Stem |
| devin@cornerloaf.example | Merchant admin, Corner Loaf Bakery |
| ops@handoff.delivery | Handoff admin |

## API (v1)

All JSON. Authenticated calls send `Authorization: Bearer <token>`.

| Method and path | What it does |
| --- | --- |
| `POST /api/v1/session` | Sign in with `email` and `password`. Returns `token`, `user`, `merchant`. |
| `DELETE /api/v1/session` | Sign out (client discards the token). |
| `GET /api/v1/me` | Current user and merchant. |
| `GET /api/v1/merchant/batches` | The merchant's batches, newest first. |
| `POST /api/v1/merchant/batches` | Multipart upload: `file` (CSV), optional `delivery_date`, `name`. Returns 202; the rows import in the background. |
| `GET /api/v1/merchant/batches/:id` | A batch with its orders and per-row problems. |
| `GET /api/v1/admin/batches?date=YYYY-MM-DD` | Staff only. Every merchant's batches for one delivery day, with totals. Optional `merchant_id`, `status`. |
| `GET /api/v1/admin/batches/:id` | Staff only. Any batch with its orders and merchant. |
| `GET /api/v1/admin/merchants` | Staff only. All merchants. |

CSV columns are matched loosely: `name`, `phone`, `email`, `address`, `unit`,
`city`, `postal_code`, `notes`, `quantity`, `leave_at_door`, `order_id`, with
common aliases such as `Customer`, `Phone Number`, `Apt`, `Postal Code`, `Qty`.
`name`, `address`, and `postal_code` are required columns.

## Tests

```sh
bundle exec rspec
```

Request specs cover sign-in, the merchant batch upload flow, and the staff
views; a service spec covers the CSV importer. Jobs run inline in tests.

Seeds also create three demo batches (two for tomorrow, one for today) so the
ops view has data on first sign-in.
