from airflow import DAG
from datetime import datetime
from airflow.operators.bash import BashOperator

with DAG(
    dag_id="my_first_dag",
    start_date= None,
    schedule='0 0 * * *',
    catchup=False
) as dag:
    hello_world = BashOperator(
        task_id='hello_world',
        bash_command='echo "Hello World!"'
    )