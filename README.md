# Symfony 4.0 + Docker

[![Build Status](https://travis-ci.org/guham/symfony-docker.svg?branch=master)](https://travis-ci.org/guham/symfony-docker)

##  Requirements

- [Docker](https://docs.docker.com/engine/installation/) installed
- [Docker Compose](https://docs.docker.com/compose/install/) installed

## Services

- PHP-FPM 7.2
- Nginx 1.13
- MySQL 5.7 | PostgreSQL 9.6 | MongoDB 3.4
- Redis 4.0
- [ELK](https://github.com/spujadas/elk-docker) (Elasticsearch 6.1.2, Logstash 6.1.2, Kibana 6.1.2)

## Installation

1. Clone this repository
    ```bash
    $ git clone https://github.com/guham/symfony-docker.git
    ```
2. Update the Docker `.env` file according to your needs. The `NGINX_HOST` environment variable allows you to use a custom server name

3. Add the server name in your system host file

4. Copy the `symfony/.env.dist` file to `symfony/.env`
    ```bash
    $ cp symfony/.env.dist symfony/.env
    ```
5. Update the database configuration according to your choice of database

    MySQL:
    ```yaml
    # symfony/config/packages/doctrine.yaml
    doctrine:
        dbal:
            driver: 'pdo_mysql'
            server_version: '5.7'
            charset: utf8mb4
            url: '%env(resolve:DATABASE_URL)%'
            # ...
    ```
    ```bash
    # symfony/.env
    DATABASE_URL=mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@mysql:3306/${MYSQL_DATABASE}
    ```
    PostgreSQL:
    ```yaml
    # symfony/config/packages/doctrine.yaml
    doctrine:
        dbal:
            driver: 'pdo_pgsql'
            server_version: '9.6'
            charset: UTF8
            url: '%env(resolve:DATABASE_URL)%'
            # ...
    ```
    ```bash
    # symfony/.env
    DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgresql:5432/${POSTGRES_DB}
    ```
    MongoDB:
    ```yaml
    # symfony/config/packages/doctrine_mongodb.yaml
    doctrine_mongodb:
        connections:
            default:
                server: '%env(MONGODB_URL)%'
                options:
                    username: '%env(MONGODB_USERNAME)%'
                    password: '%env(MONGODB_PASSWORD)%'
                    authSource: '%env(MONGO_INITDB_DATABASE)%'
        default_database: '%env(MONGODB_DB)%'
        # ...
    ```
    ```bash
    # symfony/.env
    MONGODB_URL=${MONGODB_SERVER}
    MONGODB_DB=${MONGO_INITDB_DATABASE}
    ```

6. Build & run containers with `docker-compose` by specifying a second compose file, e.g., with MySQL 
    ```bash
    $ docker-compose -f docker-compose.yml -f docker-compose.mysql.yml build
    ```
    then
    ```bash
    $ docker-compose -f docker-compose.yml -f docker-compose.mysql.yml up -d
    ```
    **Note:** for PostgreSQL, use `docker-compose.postgresql.yml` and for MongoDB `docker-compose.mongodb.yml`

7. Composer install

    first, configure permissions on `symfony/var` folder
    ```bash
    $ docker-compose exec app chown -R www-data:1000 var
    ```
    then
    ```bash
    $ docker-compose exec -u www-data app composer install
    ```

## Access the application

You can access the application both in HTTP and HTTPS:

- with `APP_ENV=dev` or `APP_ENV=prod`: [symfony-docker.localhost](http://symfony-docker.localhost)
- Kibana logs: [symfony-docker.localhost:5601](http://symfony-docker.localhost:5601)

**Note:** `symfony-docker.localhost` is the default server name. You can customize it in the `.env` file with `NGINX_HOST` variable.

## Docker-compose alternative method

In order to get rid of the second compose file (e.g.`docker-compose.mysql.yml`), [you can validate the configuration](https://docs.docker.com/compose/reference/config/) and then use another Compose file:

```bash
$ docker-compose -f docker-compose.yml -f docker-compose.mysql.yml config > docker-stack.yml 
```
then
```bash
$ docker-compose -f docker-stack.yml build
$ docker-compose -f docker-stack.yml up -d
```

Moreover, you can copy database service configuration from compose file into `docker-compose.yml` and use it as default.

## Databases

- MySQL

The `MYSQL_DATABASE` variable specifies the name of the database to be created on image startup.
User `MYSQL_USER` with password `MYSQL_PASSWORD` will be created and will be granted superuser access to this database.

- PostgreSQL

Same as MySQL but with `POSTGRES_DB`, `POSTGRES_USER` and `POSTGRES_PASSWORD` variables.

- MongoDB

The `MONGO_INITDB_DATABASE` variable specifies the name of the database to be created on image startup.
User `MONGODB_USERNAME` with password `MONGODB_PASSWORD` will be created with the `dbOwner` role to this database.
Finally, `MONGO_INITDB_ROOT_USERNAME` and `MONGO_INITDB_ROOT_PASSWORD` let you customize root user.

## Commands

**Note:** `symfony` is the default value for the user, password and database name. You can customize them in the `.env` file.

```bash
# bash
$ docker-compose exec app /bin/bash

# Symfony console
$ docker-compose exec -u www-data app bin/console

# configure permissions, e.g. on `var/log` folder
$ docker-compose exec app chown -R www-data:1000 var/log

# MySQL
# access with application account
$ docker-compose -f docker-stack.yml exec mysql mysql -usymfony -psymfony

# PostgreSQL
# access with application account
$ docker-compose -f docker-stack.yml exec postgresql psql -d symfony -U symfony

# MongoDB
# access with application account
$ docker-compose -f docker-stack.yml exec mongodb mongo -u symfony -p symfony --authenticationDatabase symfony
```