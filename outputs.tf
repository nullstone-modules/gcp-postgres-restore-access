output "env" {
  value = [
    {
      name  = "RESTORE_OWNER_ROLE"
      value = local.owner_role
    },
  ]
}

output "secrets" {
  value = [
    {
      name  = "POSTGRES_URL"
      value = local.postgres_url
    },
  ]
}
