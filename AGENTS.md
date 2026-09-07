# Handoff API: agent guide

Rails 7.2 in API mode, Postgres, Sidekiq on Redis, ActionMailer to Mailpit.
Fictional company; all data is synthetic.

## Layout

| Concern | Where |
| --- | --- |
| Routes | `config/routes.rb`. JSON API under `/api/v1`. Sidekiq Web at `/sidekiq`. |
| Controllers | `app/controllers/api/v1/`. `BaseController` does bearer auth, error rendering, and the `require_merchant!` / `require_admin!` guards. Merchant-facing controllers live in `merchant_area/` (route namespace `merchant`), staff-facing ones in `admin_area/` (namespace `admin`), courier-facing ones in `courier_area/` (namespace `courier`, `require_courier!`). |
| Auth | `app/services/auth_token.rb`, HS256 JWT, 30 day expiry, secret from `JWT_SECRET` or `secret_key_base`. |
| Serialization | `app/serializers/*_serializer.rb`, plain modules returning hashes. snake_case keys. `BatchSerializer` takes `include_merchant:` for cross-merchant views. |
| Domain services | `app/services/`. `Batches::CsvImporter` parses, validates, and geocodes uploads. `Geocoding::AddressBank` looks addresses up in the seeded bank (`lib/address_bank/`). `Offers::Dispatch`, `Offers::Accept`, `Offers::Expire` and `Stops::Complete` are the courier-side state changes; `Routing::Pay` prices a route. `Routing::Planner` builds routes for a merchant and day through a `Routing::Engine`: `Engines::VrpCli` shells out to `vendor/vrp/bin/vrp-cli` (pragmatic JSON format), `Engines::Savings` is the pure-Ruby fallback. |
| Jobs | `app/jobs/`. ActiveJob on Sidekiq. `ImportBatchJob` runs the importer and sends `BatchMailer.import_finished`. `BuildRoutesJob` runs the planner; progress lives in `route_plans`. `ExpireOffersJob` is scheduled 20 minutes after an offer goes out. |
| Mail | `app/mailers/`, text and HTML views in `app/views/`. |
| Config | `.env.development` and `.env.test` (committed, no secrets), `config/sidekiq.yml`, `docker-compose.yml` for local services, `gently/apps.yml` for the sandbox. |
| Tests | RSpec in `spec/`. Factories in `spec/factories`, helpers in `spec/support`, CSV fixture in `spec/fixtures/files`. |

## Commands

```sh
docker compose up -d
bin/rails db:prepare db:seed
bin/rails server                      # :3200 locally
bundle exec sidekiq -C config/sidekiq.yml
bundle exec rspec
bin/rubocop
```

## Rules

- **Every write path gets a request spec.** Run `bundle exec rspec` before calling a change done.
- **Seeds must stay idempotent.** `db/seeds.rb` reruns on every sandbox rebuild; use find-or-initialize and `update!`. Demo batches are keyed by merchant and name and read their CSVs from `db/seeds/`.
- **Ports are offset locally** (3200, 5440, 6390, 8026) so this project does not collide with others on the machine. Inside the sandbox the defaults apply and `DATABASE_URL`, `REDIS_URL`, `SMTP_*` are injected.
- **Status codes:** use `422` numerically rather than the `:unprocessable_entity` symbol, which Rack has renamed.
- **The `json` gem is pinned below 2.10** because ActiveSupport 7.2 still passes `quirks_mode` to `JSON.generate`. Remove the pin when Rails is upgraded.
- **CSV import problems are user-facing strings.** Keep them plain and specific; the portal shows them verbatim.
- **Geocoding never calls out.** Add streets to `lib/address_bank/streets.rb`; the seeder is idempotent and the test suite seeds the bank once in `before(:suite)`.
- **Routing is replaceable.** Add an engine under `app/services/routing/engines/`, register it in `Routing::Engine.for`, and give it the shared examples in `spec/services/routing/engines_spec.rb`. Distances are straight-line times a 1.3 detour factor; there is no road network.
- **Sidekiq does not reload code or schema.** Restart it after adding a job class or running a migration. Its process title is `sidekiq 7.x handoff-api [...]`, not the command you typed, so find it with `pgrep -f 'sidekiq.*handoff-api'` before killing it. A stale worker silently ignores new columns.
- Add new API resources under `api/v1`. An older `v0` namespace with jbuilder views is planned for the legacy story; do not add new clients to it.
