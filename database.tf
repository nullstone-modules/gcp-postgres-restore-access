// The restore swaps a staging database into the target's name, so the target has to exist before the
// first restore runs -- in a brand new environment nothing has created it yet.
//
// `useExisting` makes this inert against a database that is already there. pg-db-admin's update path
// for databases is a pure read, so an existing target keeps its owner, encoding, collation, and
// connection limit exactly as they are; `owner` below only ever applies to a database this creates.
// Its drop is a no-op too, so detaching this capability never destroys the database.
resource "restapi_object" "target_database" {
  path         = "/databases"
  id_attribute = "name"
  object_id    = local.target_database
  force_new    = [local.target_database]
  destroy_path = "/skip"

  data = jsonencode({
    name        = local.target_database
    owner       = local.owner_role
    useExisting = true
  })

  depends_on = [restapi_object.owner_role]
}
