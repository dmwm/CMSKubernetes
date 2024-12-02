DATE := $(shell date +%Y%m%d)

build:
	docker buildx build --platform=linux/amd64 --tag registry.cern.ch/cmsweb/wmcore-dev .

push:
	docker tag registry.cern.ch/cmsweb/wmcore-dev registry.cern.ch/cmsweb/wmcore-dev:$(DATE)-stable
	docker push registry.cern.ch/cmsweb/wmcore-dev:$(DATE)-stable