# Control Plane Deployment Notes

This repository uses `cpflow` for opt-in pull-request review apps, automatic
staging deploys from `main`, and manual promotion from staging to production.
The generated GitHub Actions use `cpflow` v5.3.0 and pin the immutable release
commit `b1e5ff4a04adfccfd8b59996e8abdbb5defb3fd6`; see
[`.github/cpflow-help.md`](../.github/cpflow-help.md) for the complete commands,
settings, and upgrade procedure. After regenerating wrappers for a future
release, repin them with `bin/pin-cpflow-github-ref <release-commit-sha>`.

## Runtime Shape

The app uses PostgreSQL and Sidekiq in production. The Control Plane templates
provision a stateful `postgres` workload and volume set, an internal `redis`
workload, and app-image-backed `rails` and `sidekiq` workloads. The release
script runs `bin/rails db:prepare` before a new image is made live. Capacity AI
right-sizes the Rails and Sidekiq workloads; PostgreSQL and Redis remain
manually sized. Redis stores Sidekiq queues on its volume set with append-only
persistence, and Action Cable uses the same internal Redis endpoint.
PostgreSQL does not report ready until any configured archive restore succeeds,
so release commands cannot race a partially restored database.

The generated PostgreSQL template contains review/demo-only placeholder
credentials. Replace both database secret values before bootstrapping any app,
then add a matching full `DATABASE_URL` value to that app's generated secret
dictionary. The Rails template reads `{{APP_SECRETS}}.DATABASE_URL`; never
commit the real connection string.

## One-Time Bootstrap

Create the shared review-app secret before enabling review deployments. Review
apps execute pull-request code, so use a disposable value that grants no access
to staging, production, or third-party services:

```sh
cpln secret create-dictionary \
  --name react-on-rails-open-flights-example-review-secrets \
  --org "$CPLN_ORG_STAGING" \
  --entry "SECRET_KEY_BASE=$(bin/rails secret)" \
  --entry "DATABASE_URL=postgresql://the_user:the_password@postgres:5432/the_user"
```

The disposable review URL targets the `postgres` workload inside each review
app GVC and matches the checked-in review/demo credentials. Replace
`the_user` and `the_password` in both this command and
`.controlplane/templates/postgres.yml` before bootstrapping review apps; URL
encode either value if it contains reserved URL characters.

Bootstrap the persistent staging and production apps before their first deploy:

```sh
cpflow setup-app \
  -a react-on-rails-open-flights-example-staging \
  --org "$CPLN_ORG_STAGING" \
  --skip-post-creation-hook

cpflow setup-app \
  -a react-on-rails-open-flights-example-production \
  --org "$CPLN_ORG_PRODUCTION" \
  --skip-post-creation-hook
```

Add distinct `SECRET_KEY_BASE` and `DATABASE_URL` values to the generated
staging and production app secret dictionaries. The checked-in app template
sets `REDIS_URL` to the internal Redis workload; no public Redis endpoint or
password is required. For later template changes, run `cpflow apply-template`
and ensure the app identity can `reveal` the app secret policy.

## GitHub Configuration

Store `CPLN_TOKEN_STAGING` as a repository secret. Set the repository variables
`CPLN_ORG_STAGING` to the staging Control Plane organization and
`STAGING_APP_NAME` to `react-on-rails-open-flights-example-staging`; both review
apps and automatic staging deploys use that staging organization. The review
app prefix is inferred from `.controlplane/controlplane.yml` unless
`REVIEW_APP_PREFIX` overrides it.

Create a protected `production` GitHub Environment with required reviewers and
self-review disabled. Store `CPLN_TOKEN_PRODUCTION` only as an Environment
secret, and set `CPLN_ORG_PRODUCTION` and `PRODUCTION_APP_NAME` there as
Environment variables. Do not create a repository or organization secret named
`CPLN_TOKEN_PRODUCTION`.
