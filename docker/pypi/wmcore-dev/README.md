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

## Maintainers
[@d-ylee](https://github.com/d-ylee)
[@khurtado](https://github.com/khurtado)
