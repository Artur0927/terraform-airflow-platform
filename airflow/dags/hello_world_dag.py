from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator

# Default arguments for all tasks in this DAG
default_args = {
    'owner': 'airflow',                  # The owner of the DAG
    'depends_on_past': False,            # Do not wait for previous runs
    'email_on_failure': False,           # Disable failure email alerts
    'email_on_retry': False,             # Disable retry email alerts
    'retries': 1,                        # Retry once if it fails
    'retry_delay': timedelta(minutes=5), # Wait 5 minutes before retry
}

# Define the DAG
with DAG(
    dag_id='hello_world_dag',                # Unique DAG ID
    description='A simple Hello World DAG for Airflow testing',
    default_args=default_args,
    schedule='@daily',                       # Run once a day (new syntax)
    start_date=datetime(2025, 1, 1),         # DAG start date
    catchup=False,                           # Do not backfill past dates
    tags=['example', 'tutorial'],            # Optional tags for organization
) as dag:

    # Define a simple task that prints text
    hello_task = BashOperator(
        task_id='print_hello',
        bash_command='echo "Hello, Airflow!"'
    )

    # Set task order (only one task here)
    hello_task
