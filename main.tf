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
}

module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"
}

module "service_account" {
  source = "github.com/cloud-native-toolkit/terraform-gitops-service-account.git"

  gitops_config = var.gitops_config
  git_credentials = var.git_credentials
  namespace = var.namespace
  name = local.sa_name
  server_name = var.server_name
  sccs = ["privileged"]
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

resource null_resource setup_gitops {
  depends_on = [null_resource.create_yaml]

  provisioner "local-exec" {
    command = "${local.bin_dir}/igc gitops-module '${local.name}' -n '${var.namespace}' --contentDir '${local.yaml_dir}' --serverName '${var.server_name}' -l '${local.layer}' --debug"

    environment = {
      GIT_CREDENTIALS = nonsensitive(yamlencode(var.git_credentials))
      GITOPS_CONFIG   = yamlencode(var.gitops_config)
    }
  }
}
