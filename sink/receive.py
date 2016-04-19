#!/usr/bin/env python
import pika
import psycopg2


def mq_callback(ch, method, properties, body):
  print('Received %s' % body)
  cur.execute('INSERT INTO edwintask (msg) VALUES (%s)', [body.decode('utf-8')])
  pg_conn.commit()

# TODO: wait and retry after connection fails
pg_conn = psycopg2.connect(database='postgres', user='postgres', host='db')
cur = pg_conn.cursor()
print('Creating table edwintask')
cur.execute('CREATE TABLE IF NOT EXISTS edwintask (id serial PRIMARY KEY, created timestamptz not null default current_timestamp, msg text);')
pg_conn.commit()

mq_conn = pika.BlockingConnection(pika.ConnectionParameters(
  host='queue',
  port=5672,
  virtual_host='/',
  credentials=pika.PlainCredentials('guest', 'guest')
))
channel = mq_conn.channel()

channel.queue_declare(queue='edwintask', durable=True)
channel.basic_consume(mq_callback, queue='edwintask', no_ack=True)

print('Waiting for messages.')
channel.start_consuming()
