# wmcore-dev: WMCore development image

## Overview
This image is used for running unit tests and linting for the [WMCore](https://github.com/dmwm/WMCore) repository. This image is currently used by the Jenkins CI/CD pipelines defined in [WMCore-Jenkins](https://github.com/dmwm/WMCore-Jenkins).

## Usage
1. To build the image, run `make build`
2. Push to the CERN registry with `make push`, `make push-preprod`, or `make push-stable`
  * Special account privileges are needed to push to the CERN registry.
  * `*-stable` tagged releases are not automatically cleared from the registry.
  * Currently, the date is used as a tag for `make push`, while `make push-preprod` and `make push-stable` uses a version number.
    * `make push-preprod`: Pushes the current version
    * `make push-stable`: Pushes the current version, appended with `-stable`

## Environment Variables
These are the environment variables used in `entrypoint.sh`.

| Variable             | Description                                                                         |
| :------------------- | :---------------------------------------------------------------------------------- |
| `BUILD_ID`           | Set when run from Jenkins. Indicates whether we are in Jenkins or in developer mode |
| `MY_ID`, `MY_GROUP`  | Used in Jenkins. The id and group of the user running tests                         |
| `WMCORE_ORG`         | default: `dmwm`, the organization/user of the cloned WMCore repository              |
| `WMCORE_JENKINS_TAG` | default: `master`, the tag of the WMCore-Jenkins repository to use scripts from     |
| `WMCORE_JENKINS_ORG` | default: `dmwm`, the organization/user of the cloned WMCore-Jenkins repository      |

## Maintainers
[@d-ylee](https://github.com/d-ylee)
[@khurtado](https://github.com/khurtado)
