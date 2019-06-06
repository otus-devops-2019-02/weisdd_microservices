FROM ubuntu:16.04

RUN apt-get update && apt-get install -y mongodb-server ruby-full ruby-dev build-essential git \
    && gem install bundler

RUN mkdir /reddit
WORKDIR /reddit
COPY . /reddit

COPY dist/mongod.conf /etc/mongod.conf
COPY dist/db_config /reddit/db_config
COPY dist/start.sh /start.sh

RUN bundle install && chmod 0777 /start.sh
CMD ["/start.sh"]
