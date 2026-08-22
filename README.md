# Portfolio Airflow Platform

Shared orchestration infrastructure for data engineering portfolio projects hosted on a small VPS.

The repository owns the Airflow runtime and its metadata database. Individual projects remain in separate repositories and provide their own DAGs and business logic.

```text
de-weather-project/dags ─┐
                         ├─> shared Airflow ─> PostgreSQL metadata DB
wta-tennis-analytics ────┘
```

The WTA mount will be added when that project's DAG directory and dbt project are ready. Until then, this platform runs only the weather pipeline.

## Services

- Apache Airflow 2.10.0 with LocalExecutor
- Airflow webserver bound to `127.0.0.1:8080`
- Airflow scheduler with conservative task parallelism for a 4 GB VPS
- PostgreSQL 13 metadata database

Runtime package versions are pinned to the versions already proven by the weather pipeline. Upgrading Airflow or PostgreSQL is intentionally kept separate from the infrastructure migration.

## Repository contract

Each connected project:

- keeps its DAGs and business logic in its own Git repository;
- is mounted read-only below `/opt/airflow/dags/<project>`;
- uses project-prefixed Airflow connections and variables;
- uses a dedicated single-slot Airflow pool on this VPS;
- documents any runtime dependencies that must be pinned in the platform image.

The platform repository never stores cloud credentials, API keys, database dumps, or production `.env` files.

## Initial setup

1. Copy `.env.example` to `.env`.
2. Set `WEATHER_REPO_PATH` to the absolute host path of `de-weather-project`.
3. Replace every placeholder secret in `.env`.
4. Create the local log directory and make it writable by `AIRFLOW_UID`.
5. Build the image and run the one-time `airflow-init` service.
6. Start the webserver and scheduler.

On the VPS the standalone `docker-compose` command is used. The web UI is accessed through an SSH tunnel because it is not exposed publicly.

## Existing installation migration

The weather installation must not be removed first.

1. Pause new weather runs and wait for active tasks to finish.
2. Stop the old scheduler and webserver.
3. Create a PostgreSQL dump and retain the original `de-weather-project_db_data` volume.
4. Restore the dump into this platform's new `airflow_metadata` volume.
5. Run `airflow-init`, then start the new scheduler and webserver.
6. Compare non-secret metadata counts and check DAG import errors.
7. Allow one complete scheduled weather run before retiring the old containers.

If verification fails, stop this stack and restart the old weather Compose stack. The old metadata volume is retained for at least seven days after migration.

## Adding another project

Adding a project requires an explicit read-only DAG mount in `docker-compose.yaml`, a dedicated pool, pinned runtime dependencies, and project-specific connection names. The WTA pipeline will use `wta_pool`; dbt will run in an isolated Python environment so its dependencies cannot conflict with Airflow.
