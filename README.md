# Symfony 3.4 Docker

##  Requirements

- [Docker](https://docs.docker.com/engine/installation/) installed
- [Docker Compose](https://docs.docker.com/compose/install/) installed

## Services

- PHP7-FPM 7.1
- Nginx 1.13
- MySQL 5.7 | PostgreSQL 10.1 | MongoDB 3.4
- Redis 4.0
- ELK (Elasticsearch 1.x, Logstash 1.x and Kibana 4.1.2)

## Installation

1. Clone this repo

2. Update the `.env` file according to your needs. The `NGINX_HOST` environment variable allows you to use a custom server name

3. Add the server name in your system host file

4. Update the Symfony configuration file according to your choice of database
    ```yaml
    # symfony/app/config/config.yml
    imports:
        # ...
        - { resource: db-mysql.yml } # in case of MySQL; you can set db-postgresql.yml or db-mongodb.yml
    ```

5. Build & run containers with `docker-compose` by specifying a second compose file, e.g., with MySQL 
    ```bash
    $ docker-compose -f docker-compose.yml -f docker-compose.mysql.yml build
    ```
    then
    ```bash
    $ docker-compose -f docker-compose.yml -f docker-compose.mysql.yml up -d
    ```
    **Note:** for PostgreSQL, use `docker-compose.postgresql.yml` and for MongoDB `docker-compose.mongodb.yml`

6. Composer install

    first, configure permissions on `var/logs` folder
    ```bash
    $ docker-compose exec app chown -R www-data:1000 var/logs
    ```
    then
    ```bash
    $ docker-compose exec -u www-data app composer install
    ```

## Access the application

You can access the application both in HTTP and HTTPS:

- env dev: [symfony-docker.dev/app_dev.php](http://symfony-docker.dev/app_dev.php)
- env prod: [symfony-docker.dev](http://symfony-docker.dev)
- Kibana logs: [symfony-docker.dev:81](http://symfony-docker.dev:81)

**Note:** `symfony-docker.dev` is the default server name. You can customize it in the `.env` file with `NGINX_HOST` variable.

## Docker-compose alternative method

WIP

## TODO
- [ ] Add Symfony 4 support
- [ ] Use PHP 7.2
- [ ] Update elk service