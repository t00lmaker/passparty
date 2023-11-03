# Project Name

## Description

This is a Sinatra application that uses PostgreSQL for data persistence. The application is containerized using Docker.

## Prerequisites

- Docker
- Docker Compose

## Setup

1. Clone the repository:

```bash
git clone <repository_url>
```

2. Navigate to the project directory:

```bash
cd <project_directory>
```

3. Build and start the Docker containers:

```bash
docker-compose up --build
```

4. Access localhost:4567 in your browser.



## Util Commands

1. Connect into app container:

```bash
 podman exec -it passparty_app_1 bash
```

2. Install postgres: 

```bash
apt install postgresql
```

3. Connect to database:

```bash
psql -h $DATABASE_HOST -U $DATABASE_USER -d $DATABASE_NAME 
```
