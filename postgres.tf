data "ns_connection" "postgres" {
  name     = "postgres"
  contract = "datastore/gcp/postgres:*"
}

locals {
  db_endpoint       = data.ns_connection.postgres.outputs.db_endpoint
  db_subdomain      = split(":", local.db_endpoint)[0]
  db_port           = split(":", local.db_endpoint)[1]
  postgres_ssl_mode = try(data.ns_connection.postgres.outputs.postgres_ssl_mode, "prefer")

  db_admin_func_url = data.ns_connection.postgres.outputs.db_admin_function_url
  db_admin_invoker  = data.ns_connection.postgres.outputs.db_admin_invoker
  db_admin_version  = try(data.ns_connection.postgres.outputs.db_admin_version, "0.6")

  // The managed superuser role differs by engine: cloudsqlsuperuser on Cloud SQL,
  // alloydbsuperuser on AlloyDB. Datastore modules publish it as db_superuser_role.
  superuser_role = try(data.ns_connection.postgres.outputs.db_superuser_role, "cloudsqlsuperuser")
}

locals {
  owner_role = coalesce(var.owner_role, local.block_name)
  username   = local.resource_name

  // Connects to `postgres` rather than the target: a session connected to a database cannot rename
  // it, and the swap renames two.
  admin_database = "postgres"

  postgres_url = join("", [
    "postgres://",
    urlencode(local.username), ":", urlencode(random_password.this.result),
    "@", local.db_endpoint, "/", urlencode(local.admin_database),
    "?sslmode=", urlencode(local.postgres_ssl_mode),
  ])
}

data "google_service_account_id_token" "invoker" {
  target_audience        = coalesce(local.db_admin_func_url, "https://missing-db-admin-url")
  target_service_account = local.db_admin_invoker.email
}

provider "restapi" {
  uri                  = coalesce(local.db_admin_func_url, "https://missing-db-admin-url")
  write_returns_object = true

  headers = {
    "Authorization" : "Bearer ${data.google_service_account_id_token.invoker.id_token}"
  }
}
