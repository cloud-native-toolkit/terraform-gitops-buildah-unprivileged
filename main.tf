locals {
  name          = "ocp-userspaces-daemonset"
  bin_dir       = module.setup_clis.bin_dir
  yaml_dir      = "${path.cwd}/.tmp/${local.name}/chart/${local.name}"
  layer = "infrastructure"
  application_branch = "main"
  layer_config = var.gitops_config[local.layer]
  sa_name = "ocp-userspaces-daemonset"
  values = {
    ocp-userspaces-daemonset = {
      serviceAccount = {
        name = local.sa_name
      }
      service-account = {
        create = false
        sccs = []
      }
    }
  }
  type = "base"
}

module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"
}

module "service_account" {
  source = "github.com/cloud-native-toolkit/terraform-gitops-service-account.git?ref=v1.9.0"

  gitops_config = var.gitops_config
  git_credentials = var.git_credentials
  namespace = var.namespace
  name = local.sa_name
  server_name = var.server_name
  sccs = ["privileged","anyuid"]
}

resource null_resource create_yaml {
  depends_on = [module.service_account]

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.name}' '${local.yaml_dir}'"

    environment = {
      VALUES = yamlencode(local.values)
    }
  }
}

resource gitops_module module {
  depends_on = [null_resource.create_yaml]

  name = local.name
  namespace = var.namespace
  content_dir = local.yaml_dir
  server_name = var.server_name
  layer = local.layer
  type = local.type
  branch = local.application_branch
  config = yamlencode(var.gitops_config)
  credentials = yamlencode(var.git_credentials)
}
