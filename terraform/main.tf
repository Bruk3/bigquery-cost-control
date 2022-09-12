provider "google" {
  project = var.project
  region  = var.region
}

# Compress source code
data "archive_file" "src" {
  type        = "zip"
  source_dir  = "${path.root}/../src" # Directory where your Python source code is
  output_path = "${path.root}/../generated/src.zip"
}

resource "google_storage_bucket" "bucket" {
  name = "cost-control-cloud-function" # This bucket name must be unique

}

resource "google_storage_bucket_object" "archive" {
  name   = "${data.archive_file.src.output_md5}.zip"
  bucket = google_storage_bucket.bucket.name
  source = "${path.root}/../generated/src.zip"
}

# Enable Cloud Functions API
resource "google_project_service" "cf" {
  project = var.project
  service = "cloudfunctions.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}

# TODO - Require https and have more fine-grained IAM permissions to restrict invokers 
resource "google_cloudfunctions_function" "function" {
  name        = "bigquery-cost-control-function"
  description = "A cloud function that runs queries against bigquery information schema"
  runtime     = "python37"

  environment_variables = {
    PROJECT_ID = var.project,
  }

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.archive.name
  trigger_http          = true
  entry_point           = "main" 


# Create IAM entry so all users can invoke the function
resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = google_cloudfunctions_function.function.project
  region         = google_cloudfunctions_function.function.region
  cloud_function = google_cloudfunctions_function.function.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

resource "google_service_account" "service_account" {
  account_id   = "cloud-function-invoker"
  display_name = "Cloud Function Tutorial Invoker Service Account"
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = google_cloudfunctions_function.function.project
  region         = google_cloudfunctions_function.function.region
  cloud_function = google_cloudfunctions_function.function.name

  role   = "roles/cloudfunctions.invoker"
  member = "serviceAccount:${google_service_account.service_account.email}"
}


resource "google_cloud_scheduler_job" "job" {
  name             = "cost-control-cloud-function-scheduler"
  description      = "Trigger the ${google_cloudfunctions_function.function.name} Cloud Function every 10 mins."
  schedule         = "*/10 * * * *" # Every 10 mins
  time_zone        = "America/New_York"
  attempt_deadline = "320s"

  http_target {
    http_method = "GET"
    uri         = google_cloudfunctions_function.function.https_trigger_url

    oidc_token {
      service_account_email = google_service_account.service_account.email
    }
  }
}