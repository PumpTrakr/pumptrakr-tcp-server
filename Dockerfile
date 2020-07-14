FROM ruby:2.7.0

WORKDIR /usr/src/app/

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

COPY Gemfile Gemfile.lock ./
RUN bundle install

ADD . /usr/src/app/

EXPOSE 3333

CMD ["ruby", "/usr/src/app/tcp_server.rb"]