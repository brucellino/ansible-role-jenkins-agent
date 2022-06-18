![CI](https://github.com/brucellino/ansible-role-jenkins-agent/actions/workflows/main/badge.svg)

# jenkins-agent

This is the Ansible role for a Jenkins agent.

It starts an inbound agent connector using the Jenkins remoting library.

This role provisions an image which inherits from the Jenkins inbound image by
CloudBees, but customises the entrypoint to include a Vault Agent to retrieve a
token from Vault and provision a few useful files.

This is done with Vault Agent templates.

- `ssh_key.ctmpl` : create ssh key for the jenkins user to authenticate via SSH
  to Github repositories
- `profile.ctmpl` : create a shared AWS profile for authenticating to AWS
  accounts

## Role variables

| Variable Name                      | Default                  | Description                                               |
| ---------------------------------- | ------------------------ | --------------------------------------------------------- |
| `prerequisite_packages` (map:list) | See `defaults/main.yml`  | Dictionary of lists of default packages to install per OS |
| `version`                          | `4.7`                    | Version of the Jenkins remoting library to use            |
| `vault_version`                    | `1.7.3`                  | Vault version to use                                      |
| `vault_templates`                  | `["profile", "ssh_key"]` | List of templates to use with vault agent                 |

## Testing

Infrastructure tests for the agent image are in `.pipeline/`:

- `test_user.py`: user-centric tests of agent functionality.

Security scans are completed as part of the image build process with Trivy. The
scan fails if it finds packages with vulnerabilities of severity HIGH or above.

## Images

Images are baked with Packer, using the packer template
`.pipeline/packer.pkr.hcl`. There is a single builder for the Docker Ubuntu
Focal image, which is pushed to the following registries:

- GitHub Container Registry: `ghcr.io/brucellino/jenkins-agent`

Images are tagged with the following heuristic:

- built images are tagged with the current release tag of this repository.
- HEAD is tagged with `next` and is used for testing purposes. It is not assumed
  to work
- `latest` is applied manually to the desired release.
