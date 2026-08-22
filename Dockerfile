FROM apache/airflow:2.10.0

ARG AIRFLOW_VERSION=2.10.0
ARG PYTHON_VERSION_CONSTRAINTS=3.12
ARG CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION_CONSTRAINTS}.txt"

COPY requirements.txt /tmp/platform-requirements.txt

RUN pip install --no-cache-dir \
    --constraint "${CONSTRAINT_URL}" \
    --requirement /tmp/platform-requirements.txt

