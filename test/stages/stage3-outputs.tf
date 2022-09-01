
resource local_file write_outputs {
  filename = "gitops-output.json"

  content = jsonencode({
    name        = module.buildah_unprivileged.name
    branch      = module.buildah_unprivileged.branch
    namespace   = module.buildah_unprivileged.namespace
    server_name = module.buildah_unprivileged.server_name
    layer       = module.buildah_unprivileged.layer
    layer_dir   = module.buildah_unprivileged.layer == "infrastructure" ? "1-infrastructure" : (module.buildah_unprivileged.layer == "services" ? "2-services" : "3-applications")
    type        = module.buildah_unprivileged.type
  })
}
