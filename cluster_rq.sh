#!/usr/bin/env bash

for i in rq2 rq3; do
  docker-compose -f docker-compose.yml -f docker-compose.scale_rq.yml exec "$i" \
    sh -c 'rabbitmqctl stop_app; rabbitmqctl join_cluster rabbit@rq1; rabbitmqctl start_app'
done

docker-compose -f docker-compose.yml -f docker-compose.scale_rq.yml exec rq1 rabbitmqctl cluster_status
