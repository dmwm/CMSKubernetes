WMCORE_TAG=2.4.2rc7
DATE := $(shell date +%Y%m%d)

build:
	docker buildx build --platform=linux/amd64 --build-arg PYTHON_VERSION=3.12 --build-arg WMCORE_TAG=$(WMCORE_TAG) --tag registry.cern.ch/cmsweb/wmcore-dev:py3.12-$(WMCORE_TAG) .

build-no-cache:
	docker buildx build --no-cache --platform=linux/amd64 --build-arg PYTHON_VERSION=3.12 --build-arg WMCORE_TAG=$(WMCORE_TAG) --tag registry.cern.ch/cmsweb/wmcore-dev:py3.12-$(WMCORE_TAG) .

build-dev:
	docker buildx build -f ./Dockerfile.dev --platform=linux/amd64 --build-arg PYTHON_VERSION=3.12 --build-arg WMCORE_TAG=$(WMCORE_TAG) --tag registry.cern.ch/cmsweb/wmcore-development:py3.12-${WMCORE_TAG} .

push-preprod:
	docker push registry.cern.ch/cmsweb/wmcore-dev:py3.12-$(WMCORE_TAG)

push-stable:
	docker tag registry.cern.ch/cmsweb/wmcore-dev:py3.12-$(WMCORE_TAG) registry.cern.ch/cmsweb/wmcore-dev:py3.12-$(WMCORE_TAG)-stable
	docker push registry.cern.ch/cmsweb/wmcore-dev:py3.12-$(WMCORE_TAG)-stable

push-dev:
	docker tag registry.cern.ch/cmsweb/wmcore-development:py3.12-${WMCORE_TAG} registry.cern.ch/cmsweb/wmcore-development:py3.12-${WMCORE_TAG}-stable
	docker push registry.cern.ch/cmsweb/wmcore-development:py3.12-${WMCORE_TAG}
