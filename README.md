# Email Parser - C2S Tech Test

[![CI](https://github.com/davi-canuto/c2s-tech-test/actions/workflows/ci.yml/badge.svg)](https://github.com/davi-canuto/c2s-tech-test/actions/workflows/ci.yml)

Rails application for parsing email files (.eml) and extracting customer information using background jobs.

## Documentation

```bash
# Start all services (web, db, redis, sidekiq)
docker-compose up -d

# Or using Makefile
make up
```

The application will be available at `http://localhost:3000`

## Services

- **Web**: Rails server (port 3000)
- **Database**: PostgreSQL 16 (port 5432)
- **Redis**: Redis 7 (port 6379)
- **Sidekiq**: Background job processor

## Development Commands

### Using Makefile (recommended)

```bash
make help           # Show all available commands
make up             # Start all services
make down           # Stop all services
make logs           # Show logs from all services
make logs-sidekiq   # Show Sidekiq logs only
make console        # Open Rails console
make test           # Run tests
make shell          # Open bash in web container
```

### Using docker-compose directly

```bash
docker-compose up -d              # Start all services
docker-compose down               # Stop all services
docker-compose logs -f sidekiq    # Follow Sidekiq logs
docker-compose exec web bash      # Open shell in web container
docker-compose exec web bundle exec rails console  # Rails console
```

## Environment Variables

Copy `.env.sample` to `.env` and configure:

```bash
DATABASE_HOST=db
DATABASE_USER=postgres
DATABASE_PASSWORD=postgres
DATABASE_PORT=5432
DATABASE_NAME=c2s_tech_test

RAILS_ENV=development
RAILS_MAX_THREADS=5
REDIS_URL=redis://localhost:6379/1

PORT=3000
```

## Running Tests

```bash
make test
# or
docker-compose exec web bundle exec rspec
```

### CI/CD Pipeline

The project uses GitHub Actions for continuous integration. On every push to `main` and pull request, the CI runs:

- **Security Scans**: Brakeman (Ruby) and importmap audit (JS dependencies)
- **Linting**: RuboCop with Rails Omakase style guide
- **Tests**: Full RSpec test suite with PostgreSQL and Redis services
- **Coverage**: Generates code coverage reports with SimpleCov

Check the [CI status badge](#email-parser---c2s-tech-test) above or visit the [Actions tab](https://github.com/davi-canuto/c2s-tech-test/actions) to see the latest runs.

## Background Jobs

Email processing is handled asynchronously:

1. Upload email → Creates `ParserRecord` (status: pending)
2. Job is enqueued → `ProcessEmailJob`
3. Sidekiq processes → Calls `ProcessEmail` service
4. Status updates → `processing` → `success`/`failed`
5. Customer created → If successful

Monitor Sidekiq:
```bash
make logs-sidekiq
```

## Tech Stack

- Ruby 3.2.2
- Rails 8.0.4
- PostgreSQL 16
- Redis 7
- Sidekiq 8.0
- Bootstrap 5
- Turbo & Stimulus
- Ransack (search/filtering)
- Pagy (pagination)

**De Rubista para Rubista :3**
