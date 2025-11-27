ARG RUBY_VERSION=3.2.2
FROM ruby:$RUBY_VERSION

ARG RAILS_ENV=development

RUN apt-get update -qq && \
    apt-get install -y \
    build-essential \
    libpq-dev \
    nodejs \
    postgresql-client \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /rails

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

# precompile assets for production environmnet
# 
# RUN if [ "$RAILS_ENV" = "production" ]; then \
#       SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile; \
#     fi

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]