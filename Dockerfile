# Stage 1: Builder — installs all gems including native extensions
FROM ruby:3.2.2-slim AS builder

RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev git curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test

# Stage 2: Runtime — lean image without build tools
FROM ruby:3.2.2-slim

RUN apt-get update -qq && \
    apt-get install -y libpq-dev curl && \
    rm -rf /var/lib/apt/lists/*

# Non-root user for security
RUN useradd -ms /bin/bash clark

WORKDIR /app

COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --chown=clark:clark . .

RUN chmod +x bin/docker-entrypoint

USER clark
EXPOSE 3000

ENTRYPOINT ["bin/docker-entrypoint"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
