resource "random_password" "this" {
  // Master password length constraints differ for each database engine. For more information, see the available settings when creating each DB instance.
  length      = 16
  special     = true
  min_upper   = var.strict_password_policy ? 1 : null
  min_lower   = var.strict_password_policy ? 1 : null
  min_numeric = var.strict_password_policy ? 1 : null
  min_special = var.strict_password_policy ? 1 : null

  // The password for the master database user can include any printable ASCII character except /, ", @, or a space.
  // We're also excluding the following characters:
  // ':' - not allowed by AWS DMS (Database Migration Service)
  // ';' - not allowed by AWS DMS
  // '+' - not allowed by AWS DMS
  // '%' - not allowed by AWS DMS, confuses url encoding
  // '?' - confuses url encoding
  // '#' - confuses url encoding
  // '[' - confuses url encoding
  // ']' - confuses url encoding
  // '{' - confuses url encoding
  // '}' - confuses url encoding
  // '(' - issues with batch files
  // ')' - issues with batch files
  // '&' - issues with batch files
  // '!' - issues with batch files
  // '^' - issues with batch files
  // '<' - issues with batch files
  // '>' - issues with batch files
  override_special = "$*-_="

  lifecycle {
    ignore_changes = [override_special] // Prevent changing passwords for deployed apps
  }
}
