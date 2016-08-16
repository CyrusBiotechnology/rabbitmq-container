FROM rabbitmq:management

ENV RABBITMQ_LOGS  /dev/stdout/rabbitmq.log

ADD docker-entrypoint.sh /
