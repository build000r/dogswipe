SHELL := /bin/bash

PYTHON ?= python3.12
VENV ?= .venv
SKILLS_ROOT ?= ../opensource/skills
CRAP_THRESHOLD ?= 20
PIP := $(VENV)/bin/pip
PYTEST := $(VENV)/bin/pytest
ALEMBIC := $(VENV)/bin/alembic
IOS_PROJECT ?= apps/ios/DogSwipe/DogSwipe.xcodeproj
IOS_SCHEME ?= DogSwipe
IOS_DERIVED_DATA ?= $(CURDIR)/.build/xcode-derived-data
IOS_APP_PATH ?= $(IOS_DERIVED_DATA)/Build/Products/Debug-iphoneos/DogSwipe.app
IOS_PHONE_BUNDLE_ID ?= com.build000r.dogswipe
IOS_PHONE_DEVICE_ID ?= $(shell python3 -c "import json, subprocess; devices = json.loads(subprocess.check_output(['xcrun', 'xcdevice', 'list'])); match = next((d for d in devices if not d.get('simulator') and d.get('platform') == 'com.apple.platform.iphoneos' and d.get('available')), None); print(match['identifier'] if match else '')" 2>/dev/null)
IOS_PHONE_DEVELOPMENT_TEAM ?= $(APPLE_DEVELOPMENT_TEAM)
DOGSWIPE_PHONE_API_BASE_URL ?= http://$(shell ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo localhost):8000
IOS_PHONE_SIGNING_ARGS ?= CODE_SIGNING_ALLOWED=YES CODE_SIGNING_REQUIRED=YES CODE_SIGN_STYLE=Automatic
IOS_PHONE_TEAM_ARG := $(if $(IOS_PHONE_DEVELOPMENT_TEAM),DEVELOPMENT_TEAM=$(IOS_PHONE_DEVELOPMENT_TEAM),)

.PHONY: generate-ios ios-build ios-release-assets ios-ui-test ios-screenshots require-phone-device ios-phone-build ios-phone-reset-app ios-phone-install ios-phone-launch ios-phone-run swift-test backend-install backend-install-local backend-test coverage lint typecheck migrate migration-current test drift crap mmdx-preflight deploy-config deploy-preflight deploy-overlay-template deploy-post-verify

generate-ios:
	cd apps/ios/DogSwipe && xcodegen generate

ios-build: generate-ios
	xcodebuild -project apps/ios/DogSwipe/DogSwipe.xcodeproj -scheme DogSwipe -destination 'generic/platform=iOS' build

require-phone-device:
	@if [ -z "$(IOS_PHONE_DEVICE_ID)" ]; then \
		echo "No available iPhone device detected via xcdevice."; \
		echo "Known iPhone devices:"; \
		python3 -c 'import json, subprocess; devices = json.loads(subprocess.check_output(["xcrun", "xcdevice", "list"])); iphoneos = [d for d in devices if not d.get("simulator") and d.get("platform") == "com.apple.platform.iphoneos"]; [print("- {} ({}): available={}{}".format(d.get("name"), d.get("identifier"), d.get("available"), (" " + ((d.get("error") or {}).get("description", ""))) if ((d.get("error") or {}).get("description", "")) else "")) for d in iphoneos]'; \
		exit 1; \
	fi

ios-phone-build: generate-ios
	xcodebuild -project "$(IOS_PROJECT)" -scheme "$(IOS_SCHEME)" -destination 'generic/platform=iOS' -configuration Debug -derivedDataPath "$(IOS_DERIVED_DATA)" -allowProvisioningUpdates build DOGSWIPE_API_BASE_URL="$(DOGSWIPE_PHONE_API_BASE_URL)" PRODUCT_BUNDLE_IDENTIFIER="$(IOS_PHONE_BUNDLE_ID)" $(IOS_PHONE_SIGNING_ARGS) $(IOS_PHONE_TEAM_ARG)

ios-phone-reset-app: require-phone-device
	@xcrun devicectl device uninstall app --device "$(IOS_PHONE_DEVICE_ID)" "$(IOS_PHONE_BUNDLE_ID)" >/dev/null 2>&1 || true

ios-phone-install: require-phone-device ios-phone-build
	@TMP_LOG="$$(mktemp)"; \
	if xcrun devicectl device install app --device "$(IOS_PHONE_DEVICE_ID)" "$(IOS_APP_PATH)" >"$$TMP_LOG" 2>&1; then \
		cat "$$TMP_LOG"; \
	else \
		status=$$?; \
		cat "$$TMP_LOG"; \
		if grep -Eq 'CoreDeviceError error 4000|Connection reset by peer' "$$TMP_LOG"; then \
			echo ""; \
			echo "Transient device connection reset during install. Retrying once..."; \
			if xcrun devicectl device install app --device "$(IOS_PHONE_DEVICE_ID)" "$(IOS_APP_PATH)" >"$$TMP_LOG" 2>&1; then \
				cat "$$TMP_LOG"; \
				rm -f "$$TMP_LOG"; \
				exit 0; \
			fi; \
			status=$$?; \
			cat "$$TMP_LOG"; \
		fi; \
		rm -f "$$TMP_LOG"; \
		exit $$status; \
	fi; \
	rm -f "$$TMP_LOG"

ios-phone-launch: require-phone-device
	@TMP_LOG="$$(mktemp)"; \
	if xcrun devicectl device process launch --device "$(IOS_PHONE_DEVICE_ID)" --terminate-existing "$(IOS_PHONE_BUNDLE_ID)" >"$$TMP_LOG" 2>&1; then \
		cat "$$TMP_LOG"; \
	else \
		status=$$?; \
		cat "$$TMP_LOG"; \
		if grep -Eq 'could not be unlocked|BSErrorCodeDescription = Locked' "$$TMP_LOG"; then \
			echo ""; \
			echo "Unlock the iPhone and rerun 'make ios-phone-launch'."; \
		fi; \
		rm -f "$$TMP_LOG"; \
		exit $$status; \
	fi; \
	rm -f "$$TMP_LOG"

ios-phone-run: ios-phone-install ios-phone-launch

ios-release-assets:
	python3 scripts/verify_ios_release_assets.py

ios-ui-test: generate-ios
	python3 scripts/capture_ios_screenshots.py --skip-export

ios-screenshots: generate-ios
	python3 scripts/capture_ios_screenshots.py

swift-test:
	swift test --package-path packages/DogSwipeCore

$(VENV):
	$(PYTHON) -m venv $(VENV)
	$(PIP) install --upgrade pip

backend-install: $(VENV)
	$(PIP) install -e 'backend[test]'

backend-install-local: $(VENV)
	$(PIP) install -e ../sweet-potato/packages/python-client
	$(PIP) install -e ../sweet-potato/packages/python-server-quickstart
	$(PIP) install -e 'backend[test]'

backend-test:
	cd backend && ../$(PYTEST) -q

coverage:
	cd backend && ../$(PYTEST) --cov=dogswipe_backend --cov-report=term-missing --cov-report=xml -q

lint:
	cd backend && ../$(VENV)/bin/ruff check src tests migrations

typecheck:
	cd backend && ../$(VENV)/bin/mypy src

migrate:
	cd backend && ../$(ALEMBIC) upgrade head

migration-current:
	cd backend && ../$(ALEMBIC) current

test: swift-test backend-test

drift:
	$(SKILLS_ROOT)/drift-detector/scripts/scan.sh $(CURDIR) --stack swift --all
	@total="$$(jq -r '[.summary.swift[]] | add // 0' .drift/scan.json)"; \
	if [ "$$total" -ne 0 ]; then \
		echo "SwiftUI drift findings: $$total"; \
		exit 1; \
	fi

crap:
	@test -f backend/coverage.xml || { echo "backend/coverage.xml missing; run make coverage before make crap"; exit 1; }
	@set -euo pipefail; \
	tmp="$$(mktemp)"; \
	python3 $(SKILLS_ROOT)/crap/scripts/analyze_crap.py $(CURDIR) --languages python,swift --threshold $(CRAP_THRESHOLD) --top 20 | tee "$$tmp"; \
	score="$$(awk '/^FINAL_SCORE:/ {print $$2}' "$$tmp" | tail -1)"; \
	rm -f "$$tmp"; \
	awk -v score="$$score" -v threshold="$(CRAP_THRESHOLD)" 'BEGIN { \
		if (score == "") { print "Missing FINAL_SCORE in CRAP output" > "/dev/stderr"; exit 1 } \
		if (score + 0 < threshold + 0) exit 0; \
		printf("CRAP FINAL_SCORE %.2f must be < %.2f\n", score, threshold) > "/dev/stderr"; \
		exit 1; \
	}'

mmdx-preflight:
	python3 $(SKILLS_ROOT)/mmdx/scripts/mmd.py docs/architecture.mmdx --preflight-only

deploy-config:
	DOGSWIPE_ENV_FILE=prod.env.example DOGSWIPE_IMAGE=dogswipe-api:local POSTGRES_PASSWORD=postgres docker compose --env-file deploy/prod.env.example -f deploy/docker-compose.prod.yml config >/dev/null

deploy-preflight:
	ENV_FILE=deploy/prod.env.example DOGSWIPE_ENV_FILE=prod.env.example DOGSWIPE_IMAGE=dogswipe-api:local POSTGRES_PASSWORD=postgres bash deploy/pre-deploy-checks.sh

deploy-overlay-template:
	bash deploy/validate-skillbox-overlay.sh deploy/skillbox-overlay.example.yaml --allow-placeholders

deploy-post-verify:
	bash deploy/post-deploy-verify.sh
