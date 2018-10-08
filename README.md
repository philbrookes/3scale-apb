# 3Scale APB

[![](https://img.shields.io/docker/automated/jrottenberg/ffmpeg.svg)](https://hub.docker.com/r/aerogearcatalog/3scale-apb/)
[![Docker Stars](https://img.shields.io/docker/stars/aerogearcatalog/3scale-apb.svg)](https://registry.hub.docker.com/v2/repositories/aerogearcatalog/3scale-apb/stars/count/)
[![Docker pulls](https://img.shields.io/docker/pulls/aerogearcatalog/3scale-apb.svg)](https://registry.hub.docker.com/v2/repositories/aerogearcatalog/3scale-apb/)
[![License](https://img.shields.io/:license-Apache2-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0)

## Local Development

### Requirements

- Setup OpenShift Origin [development environment](https://github.com/ansibleplaybookbundle/ansible-playbook-bundle/blob/master/docs/getting_started.md#development-environment) for APB development.
- Install [apb tool](https://github.com/ansibleplaybookbundle/ansible-playbook-bundle/blob/master/docs/apb_cli.md)

### Process

```bash
apb push
```

For more extensive documentation on APB development and apb command line options, please read the ansible playbook bundle [docs](https://github.com/ansibleplaybookbundle/ansible-playbook-bundle/tree/master/docs).

## Submitting Changes

To submit a change, please follow these instructions:

- Fork this repo.
- Make changes in your own repo, and use your own docker org while developing.
- Submit a pull request to this master on this repo.
