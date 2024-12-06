VERSION=0.2.0
DATE := $(shell date +%Y%m%d)
#DATE = 20241202

build:
	docker buildx build --platform=linux/amd64 --tag registry.cern.ch/cmsweb/wmcore-dev .

build-no-cache:
	docker buildx build --no-cache --platform=linux/amd64 --tag registry.cern.ch/cmsweb/wmcore-dev .

push:
	docker tag registry.cern.ch/cmsweb/wmcore-dev registry.cern.ch/cmsweb/wmcore-dev:$(DATE)
	docker push registry.cern.ch/cmsweb/wmcore-dev:$(DATE)
	docker tag registry.cern.ch/cmsweb/wmcore-dev registry.cern.ch/cmsweb/wmcore-dev:latest
	docker push registry.cern.ch/cmsweb/wmcore-dev:latest

push-stable:
	docker tag registry.cern.ch/cmsweb/wmcore-dev registry.cern.ch/cmsweb/wmcore-dev:$(VERSION)-stable
	docker push registry.cern.ch/cmsweb/wmcore-dev:$(DATE)-stable