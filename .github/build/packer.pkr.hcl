/*
  Packer template for base Jenkins agent image.
  This is a customisation of the default incoming agent image produced by CloudBees
  We customise the following:
  - vault agent and templates added
    - github ssh key
    - spinnaker cli configuration
  - vault agent is run once-off by the entrypoint
  - Security scan provisioner by Trivy
  - functional testing with Testinfra
*/

# jenkins_base_image is the base image which we will use to build ours from
variable "jenkins_base_image" {
  default = "jenkins/inbound-agent:jdk11"
}

variable "source_registry_secrets_mount" {
  description = "Vault KV mount path for source image registry credentials. The base image will be pulled with these credentials"
  default = "kv/data/personal/tokens"
}

variable "source_registry_token_key" {
  description = "Name of the key in the Vault mount containing the source registry token"
  default = "docker_token"
}

variable "target_registry_secrets_mount" {
  description = "Vault KV mount path for target registry credentials"
  default = "kv/data/github"
}

# container_registry_token is the field in the kv store which contains the access token
variable "target_registry_token_key" {
  description = "Vault KV key for target registry credentials"
  default = "ghcr_token"
}

locals {
  docker_hub_token  = vault(var.source_registry_secrets_mount, var.source_registry_token_key)
  github_token      = vault(var.target_registry_secrets_mount, var.target_registry_token_key)
}

variable "target_registry_username" {
  type    = string
  default = "brucellino"
}

variable "version" {
  type    = string
  default = "latest"
}

source "docker" "focal" {
  login = true
  login_username = "brucellino"
  login_password = local.docker_hub_token
  changes = [
    "USER jenkins",
    "LABEL version=${var.version}",
    "LABEL team=devops",
    "LABEL org.opencontainers.image.source=https://github.com/brucellino/ansible-role-jenkins-agent",
    "EXPOSE 50000 5000 443",
    "ENTRYPOINT [\"jenkins-agent\"]"
  ]
  commit      = true
  exec_user   = "root"
  image       = var.jenkins_base_image
  run_command = ["-d", "-i", "-t", "--name", "test_agent", "{{ .Image }}", "/bin/bash"]
}

build {
  sources = ["source.docker.focal"]

  provisioner "ansible" {
    ansible_env_vars = [
      "ANSIBLE_ROLES_PATH=../../../",
      "ANSIBLE_PYTHON_INTERPRETER=python3",
      "ANSIBLE_TRANSPORT=docker"
    ]
    extra_arguments = [
      "-e", "ansible_host=test_agent",
      "-e", "provision=false"
    ]
    groups          = ["docker", "jenkins_agents"]
    playbook_file   = "playbook.yml"
    user            = "root"
  }

  provisioner "shell-local" {
    inline = ["pytest --hosts=\"docker://root@test_agent\" test_user.py"]
  }

  provisioner "shell" {
    inline = [
      "curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin",
      "trivy fs --severity HIGH,CRITICAL --exit-code 0 --ignore-unfixed /",
      "rm -rf /usr/local/bin/trivy /root/.cache /root/.ansible"
    ]
  }

  post-processors {
    // Github Container Registry
    post-processor "docker-tag" {
      repository = "ghcr.io/brucellino/jenkins-agent"
      tags       = [var.version, "next"]
    }

    post-processor "docker-push" {
      login_server   = "ghcr.io"
      login_username = var.target_registry_username
      login_password = local.github_token
    }
  }
}
