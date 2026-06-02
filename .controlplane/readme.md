# Control Plane Deployment Notes

This repo now includes `cpflow` scaffolding for:

- opt-in PR review apps
- automatic staging deploys from `main`
- manual promotion from staging to production

## Why This Shape

This app uses PostgreSQL in production, so the Control Plane setup keeps a
stateful `postgres` workload in the same GVC as the `rails` workload.

- `.controlplane/templates/postgres.yml` provisions the Postgres volumeset,
  credentials secret, and stateful workload
- `.controlplane/templates/app.yml` sets the Rails runtime env, including
  `DATABASE_URL` and `SECRET_KEY_BASE`
- `.controlplane/release_script.sh` runs `bin/rails db:prepare` before deploys
  switch traffic to a new image

The generated `.controlplane/Dockerfile` installs Node.js alongside Ruby,
auto-installs JavaScript dependencies for npm/Yarn/pnpm projects, and leaves a
callable package-manager shim in place so `assets:precompile` can invoke `yarn`
again in later build steps.

This demo also needs the generated React on Rails SSR registry file checked in
at `app/javascript/generated/server-bundle-generated.js`. Without that file,
clean-clone Docker builds fail during asset compilation.

## Required Runtime Secrets

Before the app will boot on Control Plane, populate `SECRET_KEY_BASE` in the
generated secret dictionaries:

- `react-on-rails-open-flights-example-staging-secrets`
- `react-on-rails-open-flights-example-review-secrets`
- `react-on-rails-open-flights-example-production-secrets`

`cpflow setup-app` creates those dictionaries automatically.

Review apps run pull request code. Values mounted through `cpln://secret/...`
can be read by that code after the workload starts, so keep the review secret
dictionary limited to generated, review-only values. Do not reuse production or
long-lived staging secret dictionaries for review apps.

## Optional Runtime Variables

If you want password reset emails to work in deployed environments, also set:

- `ROOT_URL`
- `SENDGRID_API_KEY`
- `SENDGRID_USERNAME`
- `SENDGRID_PASSWORD`
- `DEFAULT_FROM_EMAIL`

## Local cpflow Flow

Typical setup:

```sh
export APP_NAME=react-on-rails-open-flights-example-staging

cpflow setup-app -a "$APP_NAME"
cpflow build-image -a "$APP_NAME"
cpflow deploy-image -a "$APP_NAME" --run-release-phase
cpflow open -a "$APP_NAME"
```

## GitHub Actions Variables And Secrets

Set these in GitHub before enabling the generated `cpflow-*` workflows:

- `CPLN_TOKEN_STAGING`
- `CPLN_TOKEN_PRODUCTION`
- `CPLN_ORG_STAGING`
- `CPLN_ORG_PRODUCTION`
- `STAGING_APP_NAME=react-on-rails-open-flights-example-staging`
- `PRODUCTION_APP_NAME=react-on-rails-open-flights-example-production`
- `REVIEW_APP_PREFIX=react-on-rails-open-flights-example-review`

Optional:

- `STAGING_APP_BRANCH=main`
- `PRIMARY_WORKLOAD=rails`

Use a staging/review `CPLN_TOKEN_STAGING` that cannot access production Control
Plane resources. In public repositories, review-app deploys skip fork PR heads
because Docker builds use repository secrets. If a forked change needs a review
app, first move the reviewed change to a trusted branch in this repository.
