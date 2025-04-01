VERSION=0.3.0
DATE := $(shell date +%Y%m%d)

build:
	docker buildx build --platform=linux/amd64 --tag registry.cern.ch/cmsweb/wmcore-dev .

build-no-cache:
	docker buildx build --no-cache --platform=linux/amd64 --tag registry.cern.ch/cmsweb/wmcore-dev .

build-dev:
	docker buildx build -f ./Dockerfile.dev --platform=linux/amd64 --tag registry.cern.ch/cmsweb/wmcore-development .

push:
	docker tag registry.cern.ch/cmsweb/wmcore-dev registry.cern.ch/cmsweb/wmcore-dev:$(DATE)
	docker push registry.cern.ch/cmsweb/wmcore-dev:$(DATE)
	docker tag registry.cern.ch/cmsweb/wmcore-dev registry.cern.ch/cmsweb/wmcore-dev:latest
	docker push registry.cern.ch/cmsweb/wmcore-dev:latest

push-preprod:
	docker tag registry.cern.ch/cmsweb/wmcore-dev registry.cern.ch/cmsweb/wmcore-dev:$(VERSION)
	docker push registry.cern.ch/cmsweb/wmcore-dev:$(VERSION)

push-stable:
	docker tag registry.cern.ch/cmsweb/wmcore-dev registry.cern.ch/cmsweb/wmcore-dev:$(VERSION)-stable
	docker push registry.cern.ch/cmsweb/wmcore-dev:$(VERSION)-stable

push-dev:
	docker tag registry.cern.ch/cmsweb/wmcore-development registry.cern.ch/cmsweb/wmcore-development:latest-stable
	docker push registry.cern.ch/cmsweb/wmcore-development:latest-stable

