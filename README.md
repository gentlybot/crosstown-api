# Handoff API

Rails 7.2 API and Sidekiq worker for **Handoff**, a fictional same-day delivery
company for local shops in Toronto. Handoff is a sample product used to demo
product workflows; this repo is its backend. The web apps live in
`handoff-apps`, the public site in `handoff-marketing`.

The backlog for all three repos is in [TODO.md](TODO.md).

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

Routing uses the [vrp-cli](https://github.com/reinterpretcat/vrp) solver, built
locally with cargo (a few minutes, once):

```sh
cargo install vrp-cli --root vendor/vrp    # binary at vendor/vrp/bin/vrp-cli, gitignored
```

Without it the API falls back to a Ruby Clarke-Wright heuristic and says so on
every route (`engine: savings`). `ROUTING_ENGINE=savings|vrp_cli|auto`
overrides the choice; `VRP_CLI_BIN` points at a binary elsewhere.

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
| jordan@courier.example | Courier |
| aisha@courier.example | Courier |

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
| `GET /api/v1/merchant/routes?date=YYYY-MM-DD` | The merchant's routing state for a day: waiting, routed, the latest run, and route summaries. |
| `POST /api/v1/merchant/routes/build` | `date`. Queues the planner for the merchant's own orders that day. Returns 202 with the plan status. |
| `GET /api/v1/admin/batches?date=YYYY-MM-DD` | Staff only. Every merchant's batches for one delivery day, with totals. Optional `merchant_id`, `status`. |
| `GET /api/v1/admin/batches/:id` | Staff only. Any batch with its orders and merchant. |
| `GET /api/v1/admin/merchants` | Staff only. All merchants. |
| `GET /api/v1/admin/routes?date=YYYY-MM-DD` | Staff only. Per merchant: what is waiting for a route, the latest routing run, and the routes with their stops and ETAs. |
| `POST /api/v1/admin/routes/build` | Staff only. `merchant_id`, `date`. Queues `BuildRoutesJob`, which replaces that merchant's planned routes for the day. Returns 202 with the plan status. |
| `GET /api/v1/admin/routes/:id` | Staff only. One route with stops and offers. |
| `POST /api/v1/admin/routes/:id/offer` | Staff only. Offers a planned route to every active courier for 20 minutes and emails them. |
| `GET /api/v1/courier/offers` | Couriers. Open offers with route summary and pay; no recipient details. |
| `POST /api/v1/courier/offers/:id/accept` | Couriers. First accept wins (409 otherwise); other offers are withdrawn. |
| `POST /api/v1/courier/offers/:id/decline` | Couriers. |
| `GET /api/v1/courier/routes`, `GET /api/v1/courier/routes/:id` | Couriers. Assigned, in-progress, and completed routes with full stop details. |
| `POST /api/v1/courier/routes/:id/start` | Couriers. Assigned to in progress. |
| `PATCH /api/v1/courier/routes/:id/stops/:stop_id` | Couriers. `status` delivered or failed, optional `note`, `failure_reason`, `photo` data URL. Emails the recipient; completes the route when every stop is settled. |

Geocoding is a lookup against a seeded **address bank** of about fifty thousand
Toronto-area civic addresses (`lib/address_bank/streets.rb`), so it works with
no network. Rows whose address is unknown are flagged "Address not found";
rows whose postal code disagrees with the address are flagged too.

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
