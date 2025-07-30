# wmcore-dev: WMCore development image

## Overview
This image is used for running unit tests and linting for the [WMCore](https://github.com/dmwm/WMCore) repository. This image is currently used by the Jenkins CI/CD pipelines defined in [WMCore-Jenkins](https://github.com/dmwm/WMCore-Jenkins).

## Usage
1. To build the image, run `make build`
  * `make build` builds the `wmcore-dev:` tagged image using `Dockerfile`
  * `make build-no-cache` builds the `wmcore-dev:` tagged image using `Dockerfile` without using the Docker cache
  * `make-build-dev` builds the `wmcore-develpment:` image using `Dockerfile.dev`
2. Push to the CERN registry with `make push-preprod`, `make push-stable`, or `make push-dev`
  * Special account privileges are needed to push to the CERN registry.
  * Currently, the date is used as a tag for `make push`, while `make push-preprod` and `make push-stable` uses a version number.
    * `make push-preprod` pushes the image tagged in `make build`
    * `make push-stable` retags the image in `make build` by adding a `-stable` suffix
      * `*-stable` tagged releases are not automatically cleared from the registry.
    * `make push-dev` pushes the `wmcore-development` image built with `make build-dev`

## Dockerfiles
* `Dockerfile`: Used to build the image for [WMCore-Jenkins](https://github.com/dmwm/WMCore-Jenkins)
* `Dockerfile-dev`: Used to build the image for [wmcore-devcontainer](https://github.com/d-ylee/WMCore-Jenkins)

## Environment Variables
These are the environment variables used in `entrypoint.sh`.

| Variable             | Description                                                                         |
| :------------------- | :---------------------------------------------------------------------------------- |
| `BUILD_ID`           | Set when run from Jenkins. Indicates whether we are in Jenkins or in developer mode |
| `MY_ID`, `MY_GROUP`  | Used in Jenkins. The id and group of the user running tests                         |
| `WMCORE_ORG`         | default: `dmwm`, the organization/user of the cloned WMCore repository              |
| `WMCORE_JENKINS_REF` | default: `main`, the ref of the WMCore-Jenkins repository to pull scripts from      |
| `WMCORE_JENKINS_ORG` | default: `dmwm`, the organization/user of the cloned WMCore-Jenkins repository      |

## Maintainers
[@d-ylee](https://github.com/d-ylee)
[@khurtado](https://github.com/khurtado)
