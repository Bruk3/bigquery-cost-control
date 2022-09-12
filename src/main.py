from google.cloud import bigquery
import os
import requests

PROJECT_ID = os.environ.get("PROJECT_ID", "jkwng-gae-flex3")
SLACK_WEBHOOK_URL = os.environ.get("SLACK_WEBHOOK_URL")
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
    message = ( 
        f"Alert: Your bigquery spend on project ${PROJECT_ID} has surpassed"
        f"the threshold value of ${THRESHOLD} dollars."
        f"Most recent total cost is ${cost} dollars"
    )
    slack_body = {"text": message}
    requests.post(
        slack_webhook_url,
        headers = ["Content-Type": "application/json"],
        data = json.dumps(slack_body)
    )
    return True




def main(request):
    print("running query")
    query_job = client.query(query)
    rows = query_job.result()
    
    for row in rows: 
        # There should be only one resulting row in the above query
        total_cost = row["costInDollars"]

    total_cost = float(total_cost)
    if total_cost > THRESHOLD:
        try:
            send_alert(total_cost)
        except Exception as err:
            print("Slack notification failed")
            print(err)



    print("costInDollars: ", total_cost)
    return f'Query run successfully. costInDollars is: {total_cost}'

