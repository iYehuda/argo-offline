.PHONY: clean dist-dir clone-charts image-list clone-images archive all

DIST_DIR := dist
IMAGE_LIST_FILE_NAME := images.txt
IMAGE_LIST := $(DIST_DIR)/$(IMAGE_LIST_FILE_NAME)
HELM_PROJECT := argo-helm
HELM_PROJECT_PATH := $(DIST_DIR)/$(HELM_PROJECT)
ARCHIVE_FILE := $(DIST_DIR)/argo.tar

clean:
	@echo Cleaning up...
	@rm -rf $(DIST_DIR)

dist-dir:
	@echo Ensuring dist dir exists...
	@mkdir -p $(DIST_DIR)

clone-charts: dist-dir
	@echo Cloning charts repository...
	@test -d $(HELM_PROJECT_PATH) || git clone https://github.com/argoproj/argo-helm.git $(HELM_PROJECT_PATH)

image-list: clone-charts
	@echo Extracting image list...
	@for VALUES_FILE in $$(find $(HELM_PROJECT_PATH) -name values.yaml); do \
		CHART_FILE=$$(dirname $$VALUES_FILE)/Chart.yaml; \
		VERSION=$$(yq -Mr '.appVersion' $$CHART_FILE); \
		./extract_images.py $$VALUES_FILE $$VERSION; \
	done | sort | uniq > $(IMAGE_LIST)

pull-images: image-list
	@echo Pulling images...
	@IFS='\n'
	for IMAGE in $$(cat ./dist/images.txt); do \
		docker pull $$IMAGE; \
	done

archive: pull-images
	@echo Archiving images...
	@docker save -o $(ARCHIVE_FILE) $$(cat $(IMAGE_LIST))

load:
	@echo Loading images from archive...
	@docker load -i $(ARCHIVE_FILE)

retag:
	@echo Retagging images...
ifndef TARGET_REGISTRY
	$(error TARGET_REGISTRY must be set)
else
	@IFS='\n'
	@for IMAGE in $$(cat ./dist/images.txt); do \
		NEW_IMAGE=$$(echo $$IMAGE | awk -F/ '{ $$1 = ($$1 ~ /\./ ? "$(TARGET_REGISTRY)" : "$(TARGET_REGISTRY)/"$$1) } 1' OFS=/); \
		docker tag $$IMAGE $$NEW_IMAGE; \
	done
endif

push:
	@echo Pushing images...
ifndef TARGET_REGISTRY
	$(error TARGET_REGISTRY must be set)
else
	@IFS='\n'
	@for IMAGE in $$(cat ./dist/images.txt); do \
		NEW_IMAGE=$$(echo $$IMAGE | awk -F/ '{ $$1 = ($$1 ~ /\./ ? "$(TARGET_REGISTRY)" : "$(TARGET_REGISTRY)/"$$1) } 1' OFS=/); \
		docker push $$NEW_IMAGE; \
	done
endif
