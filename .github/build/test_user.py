import pytest


def test_jenkins_group(host):
    """
    Ensure that the group jenkins is present
    and that jenkins user is a member of it
    """
    assert host.group("jenkins").exists
    assert host.group("jenkins").gid == 1000

    assert host.user("jenkins").exists
    assert "jenkins" in host.user("jenkins").groups
    assert host.user("jenkins").home == "/home/jenkins"

    assert host.user("jenkins").shell == "/bin/bash"


def test_jenkins_home(host):
    """
    Ensure that the jenkins user owns its own home directory
    """

    jenkins_home = host.file("/home/jenkins")
    assert jenkins_home.exists
    assert jenkins_home.is_directory
    assert jenkins_home.user == "jenkins"
    assert jenkins_home.mode == 493


def test_java(host):
    """
    Ensure that the JVM is present and is jdk 11
    """
    assert "11" in host.run("java -version").stderr
    # assert host.package("openjdk-11-jre-headless").is_installed


def test_agent(host):
    """
    Ensure that the agent startup script is present and properly configured
    """
    agent_jar = host.file("/usr/share/jenkins/agent.jar")
    start_script = host.file("/usr/local/bin/jenkins-agent")

    assert agent_jar.exists
    assert agent_jar.mode == 420
    assert agent_jar.user == "root"
    assert agent_jar.group == "root"

    assert start_script.exists

    assert host.exists("jenkins-agent")


@pytest.mark.parametrize(
    "command",
    ["pip3", "git", "vault", "bash", "pwsh", "curl", "java"],
)
def test_commands(host, command):
    """
    Ensure that required binaries are on our path
    """

    assert host.exists(command)


# def test_server(host):
#     """
#     Ensure that we can reach the jenkins server
#     at https://jenkins.domain
#     """
#     jenkins_server = host.addr("jenkins.domain")
#     assert jenkins_server.is_resolvable
