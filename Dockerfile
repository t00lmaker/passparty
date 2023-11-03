# Dockerfile
FROM docker.io/library/ruby

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

CMD ["rackup", "-o", "0.0.0.0", "-p", "4567"]