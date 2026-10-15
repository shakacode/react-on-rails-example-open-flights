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

Database credentials are provisioned outside the templates. `setup-app` and
`apply-template` reference the existing `<app-name>-pg` secret and never write
its username or password. This avoids resetting live database credentials when
applying a template update. PostgreSQL remains internal to each app GVC.

## One-Time Bootstrap

Before `setup-app`, provision a dictionary secret named `<app-name>-pg` with
`username` and `password` fields through the approved secret-management path.
Use distinct credentials for staging, production, and each disposable review
app. Do not commit credentials or put them in workflow variables. Existing
PostgreSQL volumes retain their initialized password; rotating the secret alone
does not rotate the database role.

Provision the app secret dictionary with `SECRET_KEY_BASE`, `DATABASE_URL`,
`ROOT_URL`, and any mail settings used below. For a review app, cpflow uses the
shared `react-on-rails-open-flights-example-review-secrets` dictionary, which must
contain only disposable, review-scoped values. The `DATABASE_URL` must match the
provisioned database role and address `postgres.<app-name>.cpln.local:5432`.
A shared review secret cannot contain different URLs for concurrent app GVCs:
keep review deployment disabled until a per-review secret provisioning path is
reviewed and configured. The caller defaults to disabled: set repository variable
`OPEN_FLIGHTS_REVIEW_APPS_ENABLED=true` only after that path is in place. This PR
does not automate credential provisioning.

Password reset mail uses SendGrid SMTP. Pull-request code can read every review
app secret, so use only a restricted, disposable review API key and an approved
review sender. Each review app uses its platform-provided
`CPLN_GLOBAL_ENDPOINT` as the reset origin, so request and forwarded host
headers cannot alter emailed links. The shared `ROOT_URL` is the fallback when
that runtime value is unavailable and for jobs queued before this flow was
installed. Omit password-reset testing rather than exposing staging or
production mail credentials to a review app.

Bootstrap staging before its first deploy. Production remains unconfigured
(`my-org-production`) and requires a separate reviewed setup before promotion:

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

Add distinct `SECRET_KEY_BASE`, `DATABASE_URL`, `ROOT_URL`,
`SENDGRID_USERNAME`, `SENDGRID_PASSWORD`, and `DEFAULT_FROM_EMAIL` values to the
generated staging and production app secret dictionaries. Set each `ROOT_URL`
to that app's public HTTPS endpoint, and use environment-specific SendGrid
credentials and approved sender addresses. The checked-in app template sets
`REDIS_URL` to the internal Redis workload; no public Redis endpoint or password
is required. For later template changes, run `cpflow apply-template` and ensure
the app identity can `reveal` the app secret policy.

## GitHub Configuration

Store `CPLN_TOKEN_STAGING` as a repository secret. Set the repository variables
`CPLN_ORG_STAGING` to `shakacode-open-source-examples-staging` and
`STAGING_APP_NAME` to `react-on-rails-open-flights-example-staging`; both review
apps and automatic staging deploys use that staging organization. The review
app prefix is inferred from `.controlplane/controlplane.yml` unless
`REVIEW_APP_PREFIX` overrides it.

Create a protected `production` GitHub Environment with required reviewers and
self-review disabled. Store `CPLN_TOKEN_PRODUCTION` only as an Environment
secret, and set `CPLN_ORG_PRODUCTION` and `PRODUCTION_APP_NAME` there as
Environment variables. Do not create a repository or organization secret named
`CPLN_TOKEN_PRODUCTION`.

## Rollout verification

The Rails readiness probe requests `/hello_world` so a failed SSR render keeps
its replica unready. After deployment, verify the healthy latest replica and
its image commit, then smoke `/`, `/hello_world`, airline navigation, and greeting
input. Readiness alone does not prove browser hydration or the home page.

This PR configures the deployment path for review; no persistent app, credential,
GitHub variable, production environment, or branch protection is created by it.
The staging bootstrap and GitHub settings above remain required before merge.
The stable React on Rails 17.2 upgrade and home/client rendering repairs are
tracked separately in PR #32.
