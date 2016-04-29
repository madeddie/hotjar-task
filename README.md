# Hotjar DevOps Engineer Task

A simple setup created to demonstrate ability as required by the Hotjar hiring procedure.

## Objectives

The task objectives were as follows:

* App written in Lua running in Nginx
* Some message queueing mechanism
* PostgreSQL DB

The app will have an /post endpoint to receive random POST'ed strings to be sent via message queue and received by a sink writing the strings to the PostgreSQL DB.

Next to the /post endpoint it will have a /get endpoint that when queried with a GET request will output the last 100 posted entries.

## Choices

Design and engineering decisions I made.

### Nginx & Lua

As Nginx distribution I went with [Openresty][] since this is the de facto standard for running Lua code in Nginx.

[openresty]: https://openresty.org/en/

### Message Queue

For the queueing mechanism I was set on using one of [RedisMQ][], [SQS][] or [RabbitMQ][].

- RedisMQ is a slightly esoteric solution. I found this use of Redis interesting and also easy to manage if used with AWS [ElastiCache][]. I decided it might be too esoteric.
- SQS is a very useful and relatively simple queueing service, which is completely managed by AWS. In an environment with mostly AWS technology, I would probably have preferred using this, but after a quick chat with Erik decided against using it, since in a proper production situation the vendor lock-in would not be worth it.
- RabbitMQ was the eventual choice, mostly because I know it really well, have used it often and there are lots of libraries in most languages, making writing code for it very simple.

Because of the fact the data I was dealing with was simple (and unspecified) and the setup of App, Queue, Sink, DB very straightforward I decided to use the [STOMP][] protocol on top of RabbitMQ (STOMP stands for Simple Text Oriented Messaging Protocol, the Simple part being my focus). Also, I found some ready-to-use [Lua code for interacting with a STOMP server][rabbitmqstomp] which made the choice even easier.

Also crossed my mind had Kafka (never used in production), ActiveMQ (unwieldy, in my experience), NATS (only because Erik had mentioned it, never even played with), ZeroMQ (one of my favorites in mostly fully Python based environments, but I feel not really compatible with the sink paradigm).

[redismq]: https://github.com/adjust/redismq
[sqs]: https://aws.amazon.com/sqs/
[rabbitmq]: https://www.rabbitmq.com/
[elasticache]: https://aws.amazon.com/elasticache/faqs/#redis-features
[stomp]: http://stomp.github.io/
[rabbitmqstomp]: https://github.com/wingify/lua-resty-rabbitmqstomp

### Sink code

The sink I wrote in Python, because Python is just awesome. 
For interacting with RabbitMQ I've used the [Pika][] package and for talking with the PostgreSQL database I've used [Psycopg2][], both are pretty much the standard choices for both.

[pika]: http://pika.readthedocs.io/
[psychopg2]: http://initd.org/psycopg/

### Database

PostgreSQL, because... it was part of the task. It's fine, nothing wrong with PostgreSQL.

### Installation & Management

I chose to create the whole setup in Docker containers, managed with Docker Compose. The reason for this setup is my current affinity with Docker and ease of developing in a clean environment on my laptop. Also the fact that there are ready-made solutions for [Openresty][docker-openresty], [RabbitMQ][docker-rabbitmq], [PostgreSQL][docker-postgresql] and [Python][docker-python] code already packaged in functional Docker images makes my lazy bones happy.

[docker-openresty]: https://hub.docker.com/r/ficusio/openresty/
[docker-rabbitmq]: https://hub.docker.com/_/rabbitmq/
[docker-postgresql]: https://hub.docker.com/_/postgres/
[docker-python]: https://hub.docker.com/_/python/

## How to run

To play with this setup you'll need to have git, docker and docker-compose installed and ready to go.

### Initial startup

After checking out the code from git, you can fire it up with `docker-compose up -d`. This'll build specially configured containers of RabbitMQ and the Python-based sink and will download images for Openresty and PostgreSQL.
Docker Compose set ups a user-defined network where all containers are connected too and makes it possible to find each other by name (buit-in DNS).
The freshly built and pulled containers will all be started in a certain order and with specified configuration.
By default there is one of each container;

- Openresty named web, listening to the outside world on port 80
- RabbitMQ named rq1 with alias queue, listening on a randomly chosen port for RabbitMQ admin UI
- Sink named sink
- PostgreSQL named db

You can use the command `docker-compose logs` to view the output of all the containers (and applications running in them). Add `-f` to have file change following (like tail -f).

### Testing the whole setup

After the whole setup has started up (you can check the status of all containers with `docker-compose ps`), you can test the app itself.

As mentioned there are 2 endpoints, a possible way to test them is with curl:

- /post: `curl -XPOST -d 'something random or maybe funny' http://localhost/post`
- /get: `curl -XGET http://localhost/get`

where I use localhost, you might need to enter the IP of your Docker host. Using Docker Toolbox on OSX for instance, it'll be 192.168.99.100.
You can also use other HTTP clients to test this, but just remember that the /post endpoint _only_ accepts POST requests and de /get endpoint only GET.

If you keep `docker-compose logs -f` running in another windows/terminal, you can see the data be received by the web container, then sink container and the rq container will mention connections as well.

### Enable clustered RabbitMQ

The task made mention of allowing for multiple installations of all the parts, for resiliency. Mostly achieved by loadbalancing or clustering.
I've made some small additions to allow to set up a clustered RabbitMQ configuration.

To add 2 extra rq containers, execute `docker-compose -f docker-compose.yml -f docker-compose.scale_rq.yml up -d`. To retrieve the logs and show the state of all containers from now on use the double -f form, for instance `docker-compose -f docker-compose.yml -f docker-compose.scale_rq.yml logs`.

You will now have 3 rq containers, most probably called hotjar-task_rq1_1, *_rq2_1 and *_rq3_1. These are not yet clustered. The sink app connects to the first container named `queue` from the start (remember the alias), If you would now send a message on the /post endpoint of the app, there's a chance the message will end up stuck in one of the other 2 rq containers' queues.

To cluster all rq containers execute the `cluster_rq.sh` shell script. It executes some commands directly in the containers using `docker-compose exec`.

After this, if you try to /post messages again, you might see logs from all 3 rq containers, but the sink will receive all messages, no matter which of the containers it is connected to.

### Break it down

To remove the whole setup execute `docker-compose -f docker-compose.yml -f docker-compose.scale_rq.yml down`. If you skipped the clustering step, you can leave off the -f parameters, but they don't hurt in any case.

## What is still missing?

Obviously this was just a task to test my skill, experience and reasoning. Therefore the code is far from production-ready or even completely to my own liking. It's a matter of effort versus time, benefit versus input, etc.

### Functionality

- Python sink app only connects to one queue container and never looks back nor tries again (it actually fails if the queue container doesn't answer and only because of Docker's automatic restart is that hardly ever a problem in this setup)
- Python sink app never actually checks if the DB insert has been succesful before acknowledging (and by that removing from queue) the message
- Overall the whole setup would need quite some sanity and health checking to allow for inevitable, intermittent failures
- Just receiving random strings is probably not that useful, some API design for the /post endpoint and standardization of the /get output is in order
- There is only rudimentary data hygiene being performed in the form of HTML entity substition, it's still quite far from being safe or sane
- Probably some unique ID generation in the app to allow for some form of duplicate filtering

### Tests

- I've added a couple of Nginx tests that are completely useless, since they only actually test Nginx and not the Lua code of my app
- Python app needs unit tests, testing for graceful queue and db connectivity failures, db insert failures and corrupted or duplicate messages
- Lua code need basicly the same tests as Python app along with sql injection and xss vulnerability tests
