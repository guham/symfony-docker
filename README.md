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

- env dev: [symfony-docker.localhost/app_dev.php](http://symfony-docker.localhost/app_dev.php)
- env prod: [symfony-docker.localhost](http://symfony-docker.localhost)
- Kibana logs: [symfony-docker.localhost:81](http://symfony-docker.localhost:81)

**Note:** `symfony-docker.localhost` is the default server name. You can customize it in the `.env` file with `NGINX_HOST` variable.

## Docker-compose alternative method

In order to get rid of the second compose file (e.g.`docker-compose.mysql.yml`), you can "merge" both compose files in another one:

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

## TODO
- [ ] Add Symfony 4 support
- [ ] Use PHP 7.2
- [ ] Update elk service