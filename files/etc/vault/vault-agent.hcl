pid_file = "vault_pid"

exit_after_auth = true

vault {
  # address = "<your_vault_server>"

  retry = {
    num_retries = 5
  }
}

auto_auth {
  method "approle" {
    mount_path = "auth/approle-jenkins"

    config {
      type                                = "approle"
      role                                = "<your_role>"
      role_id_file_path                   = "/tmp/role_id"
      secret_id_file_path                 = "/tmp/secret_id"
      remove_secret_id_file_after_reading = true
    }
  }

  sink "file" {
    config = {
      path = "/tmp/.token"
    }
  }
}

template "ssh_key" {
  create_dest_dirs = true
  source           = "/etc/vault/templates/ssh_key.ctmpl"
  destination      = "/home/jenkins/.ssh/ssh_key"
  perms            = "0400"
}

template "aws_profile" {
  create_dest_dirs = true
  source           = "/etc/vault/templates/profile.ctmpl"
  destination      = "/home/jenkins/.aws/credentials"
  perms            = "0600"
}

template "spin_cli_conf" {
  create_dest_dirs = true
  source           = "/etc/vault/templates/spin_cli_conf.ctmpl"
  destination      = "/home/jenkins/.spin/config"
}
