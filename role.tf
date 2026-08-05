// The restore role is an instance-level admin.
//
// It needs CREATEDB (to create the staging database *and* to rename databases at all), ownership of
// the target, the ability to terminate other sessions, and the ability to create non-trusted
// extensions. Membership in the managed superuser role covers all of it in one grant.
//
// Production gating is structural rather than a flag: attach this capability only to apps in
// environments that restore, and the role does not exist anywhere else.
resource "restapi_object" "role" {
  path         = "/roles"
  id_attribute = "name"
  object_id    = local.username
  force_new    = [local.username]
  destroy_path = "/skip"

  data = jsonencode({
    name     = local.username
    password = random_password.this.result
    attributes = {
      createDb = true
    }
    useExisting = true
  })
}

resource "restapi_object" "superuser_role_member" {
  path         = "/roles/${local.superuser_role}/members"
  id_attribute = "member"
  object_id    = "${local.superuser_role}::${local.username}"
  force_new    = [local.superuser_role, local.username]
  read_path    = "/roles/${local.superuser_role}/members/${local.username}"
  update_path  = "/roles/${local.superuser_role}/members/${local.username}"
  destroy_path = "/skip"

  data = jsonencode({
    target      = local.superuser_role
    member      = local.username
    useExisting = true
  })

  depends_on = [restapi_object.role]
}

// The restored objects must end up owned by the role that owned them before the swap, or the
// applications lose access to their own tables. pg_restore --role creates them owned correctly from
// the start, which is why there is no REASSIGN OWNED pass anywhere in the restore.
resource "restapi_object" "owner_role_member" {
  path         = "/roles/${local.owner_role}/members"
  id_attribute = "member"
  object_id    = "${local.owner_role}::${local.username}"
  force_new    = [local.owner_role, local.username]
  read_path    = "/roles/${local.owner_role}/members/${local.username}"
  update_path  = "/roles/${local.owner_role}/members/${local.username}"
  destroy_path = "/skip"

  data = jsonencode({
    target      = local.owner_role
    member      = local.username
    useExisting = true
  })

  depends_on = [restapi_object.role]
}
