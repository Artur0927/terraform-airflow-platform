from datetime import datetime

from airflow import DAG
from airflow.models import Variable
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.operators.python import PythonOperator


BUCKET_NAME = Variable.get("s3_bucket_name", default_var="airflow-data-platform-dev-bucket")
S3_KEY = "raw/sales.csv"


def create_table():
    pg_hook = PostgresHook(postgres_conn_id="dwh_postgres")
    sql = """
    CREATE TABLE IF NOT EXISTS sales (
        order_id INT,
        order_date DATE,
        customer TEXT,
        amount NUMERIC
    );
    """
    pg_hook.run(sql)


def load_from_s3():
    s3 = S3Hook(aws_conn_id="aws_default")
    file_path = s3.download_file(
        key=S3_KEY,
        bucket_name=BUCKET_NAME,
        local_path="/tmp"
    )

    pg_hook = PostgresHook(postgres_conn_id="dwh_postgres")
    with open(file_path, "r") as f:
        next(f)  # skip header
        pg_hook.copy_expert(
            sql="COPY sales FROM STDIN WITH CSV HEADER",
            filename=file_path
        )


with DAG(
    dag_id="elt_s3_to_postgres",
    start_date=datetime(2025, 1, 1),
    schedule_interval=None,
    catchup=False,
    tags=["etl", "s3", "postgres"],
) as dag:

    create_table_task = PythonOperator(
        task_id="create_table",
        python_callable=create_table,
    )

    load_data_task = PythonOperator(
        task_id="load_data_from_s3",
        python_callable=load_from_s3,
    )

    create_table_task >> load_data_task
