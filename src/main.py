from google.cloud import bigquery
import os

PROJECT_ID = os.environ.get("PROJECT_ID", "jkwng-gae-flex3")
THRESHOLD = os.environ.get("THRESHOLD", )
client = bigquery.Client(project=PROJECT_ID)

query = """
SELECT
  SUM(total_bytes_billed)/1e12*5 costInDollars, 
FROM
  `region-us`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
WHERE
  creation_time BETWEEN TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
  AND CURRENT_TIMESTAMP()
  AND job_type = "QUERY"
    """



def send_alert(cost):




def main(request):
    print("running query")
    query_job = client.query(query)
    rows = query_job.result()
    

    for row in rows: 
        # There should be only one resulting row in the above query
        total_cost = row["costInDollars"]

    total_cost = float(total_cost)
    if total_cost > THRESHOLD:
        send_alert(total_cost)



    print("costInDollars: ", total_cost)
    return f'Query run successfully. costInDollars is: {total_cost}'

