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
IOS_RELEASE_BUNDLE_ID ?= com.build000r.dogswipe
IOS_RELEASE_DEVELOPMENT_TEAM ?= $(APPLE_DEVELOPMENT_TEAM)
IOS_RELEASE_ARCHIVE_PATH ?= $(CURDIR)/.build/ios-release/DogSwipe.xcarchive
IOS_RELEASE_EXPORT_PATH ?= $(CURDIR)/.build/ios-release/export
IOS_RELEASE_EXPORT_OPTIONS ?= deploy/ios-export-options.app-store-connect.plist
IOS_TESTFLIGHT_UPLOAD_OPTIONS ?= deploy/ios-export-options.testflight-upload.plist
IOS_RELEASE_SIGNING_ARGS ?= CODE_SIGNING_ALLOWED=YES CODE_SIGNING_REQUIRED=YES CODE_SIGN_STYLE=Automatic
AASA_RENDER_PATH ?= $(CURDIR)/.build/aasa/apple-app-site-association
AASA_APPLE_TEAM_ID ?= $(IOS_RELEASE_DEVELOPMENT_TEAM)
DEPLOY_OVERLAY_FILE ?= deploy/skillbox-overlay.example.yaml
ALLOW_PLACEHOLDERS ?= false
CHECK_ASC_KEY ?= false
CHECK_DNS ?= false
CHECK_PUBLIC_URLS ?= false
DOGSWIPE_EXPECTED_A_RECORD ?= $(DOGSWIPE_DEPLOY_IP)
DOGSWIPE_RELEASE_SPAPS_API_BASE_URL ?= https://api.sweetpotato.dev
DOGSWIPE_RELEASE_AUTH_REDIRECT_URL ?= $(if $(DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN),https://$(DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN)/auth,)
DOGSWIPE_RELEASE_AUTH_UNIVERSAL_LINK_HOSTS ?= $(DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN)
DOGSWIPE_RELEASE_SPAPS_ORIGIN ?= $(if $(DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN),https://$(DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN),)
WRANGLER ?= npx wrangler
EDGE_WORKER_CONFIG ?= workers/dogswipe-edge/wrangler.jsonc
EDGE_PUBLIC_HEALTH_URL ?= https://dogswipe.buildooor.com/health
EDGE_PUBLIC_AASA_URL ?= https://dogswipe.buildooor.com/.well-known/apple-app-site-association
EDGE_CURL_RESOLVE ?=
EDGE_CURL_RESOLVE_ARG := $(if $(EDGE_CURL_RESOLVE),--resolve $(EDGE_CURL_RESOLVE),)

.PHONY: generate-ios ios-build ios-release-assets ios-ui-test ios-screenshots require-phone-device ios-phone-build ios-phone-reset-app ios-phone-install ios-phone-launch ios-phone-run require-ios-release-env require-ios-archive require-ios-asc-key ios-release-archive ios-testflight-export ios-testflight-upload swift-test backend-install backend-install-local backend-test coverage lint typecheck migrate migration-current test drift crap mmdx-preflight spaps-app-contract spaps-registration-payload spaps-origin-handoff spaps-origin-handoff-template edge-dry-run edge-deploy edge-verify deploy-config deploy-preflight deploy-render-aasa deploy-dns-handoff deploy-dns-handoff-template deploy-dns-preflight deploy-dns-preflight-template deploy-live-readiness deploy-live-readiness-template deploy-release-readiness deploy-overlay-template deploy-private-handoff-template deploy-post-verify

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

require-ios-release-env:
	@missing=""; \
	for assignment in \
		"IOS_RELEASE_DEVELOPMENT_TEAM=$(IOS_RELEASE_DEVELOPMENT_TEAM)" \
		"DOGSWIPE_RELEASE_API_BASE_URL=$(DOGSWIPE_RELEASE_API_BASE_URL)" \
		"DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN=$(DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN)" \
		"DOGSWIPE_RELEASE_SPAPS_API_BASE_URL=$(DOGSWIPE_RELEASE_SPAPS_API_BASE_URL)" \
		"DOGSWIPE_RELEASE_SPAPS_PUBLISHABLE_KEY=$(DOGSWIPE_RELEASE_SPAPS_PUBLISHABLE_KEY)" \
		"DOGSWIPE_RELEASE_SPAPS_ORIGIN=$(DOGSWIPE_RELEASE_SPAPS_ORIGIN)" \
		"DOGSWIPE_RELEASE_AUTH_REDIRECT_URL=$(DOGSWIPE_RELEASE_AUTH_REDIRECT_URL)" \
		"DOGSWIPE_RELEASE_AUTH_UNIVERSAL_LINK_HOSTS=$(DOGSWIPE_RELEASE_AUTH_UNIVERSAL_LINK_HOSTS)"; do \
		name="$${assignment%%=*}"; \
		value="$${assignment#*=}"; \
		if [ -z "$$value" ]; then missing="$$missing $$name"; fi; \
	done; \
	if [ -n "$$missing" ]; then \
		echo "Missing iOS release settings:$$missing"; \
		echo "Set these from the private deploy/signing environment before archiving."; \
		exit 1; \
	fi

require-ios-archive:
	@test -d "$(IOS_RELEASE_ARCHIVE_PATH)" || { \
		echo "Missing archive: $(IOS_RELEASE_ARCHIVE_PATH)"; \
		echo "Run 'make ios-release-archive' after configuring Apple signing and production app settings."; \
		exit 1; \
	}

require-ios-asc-key:
	@missing=""; \
	for assignment in \
		"ASC_KEY_PATH=$(ASC_KEY_PATH)" \
		"ASC_KEY_ID=$(ASC_KEY_ID)" \
		"ASC_ISSUER_ID=$(ASC_ISSUER_ID)"; do \
		name="$${assignment%%=*}"; \
		value="$${assignment#*=}"; \
		if [ -z "$$value" ]; then missing="$$missing $$name"; fi; \
	done; \
	if [ -n "$$missing" ]; then \
		echo "Missing App Store Connect API key settings:$$missing"; \
		echo "Keep the .p8 key outside git; .gitignore blocks common Apple signing artifacts."; \
		exit 1; \
	fi; \
	test -f "$(ASC_KEY_PATH)" || { echo "ASC_KEY_PATH does not exist: $(ASC_KEY_PATH)"; exit 1; }

ios-release-archive: require-ios-release-env generate-ios
	@mkdir -p "$(dir $(IOS_RELEASE_ARCHIVE_PATH))"
	@xcodebuild \
		-project "$(IOS_PROJECT)" \
		-scheme "$(IOS_SCHEME)" \
		-destination 'generic/platform=iOS' \
		-configuration Release \
		-archivePath "$(IOS_RELEASE_ARCHIVE_PATH)" \
		-allowProvisioningUpdates \
		archive \
		PRODUCT_BUNDLE_IDENTIFIER="$(IOS_RELEASE_BUNDLE_ID)" \
		DEVELOPMENT_TEAM="$(IOS_RELEASE_DEVELOPMENT_TEAM)" \
		DOGSWIPE_API_BASE_URL="$(DOGSWIPE_RELEASE_API_BASE_URL)" \
		DOGSWIPE_ASSOCIATED_DOMAIN="$(DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN)" \
		DOGSWIPE_SPAPS_API_BASE_URL="$(DOGSWIPE_RELEASE_SPAPS_API_BASE_URL)" \
		DOGSWIPE_SPAPS_PUBLISHABLE_KEY="$(DOGSWIPE_RELEASE_SPAPS_PUBLISHABLE_KEY)" \
		DOGSWIPE_SPAPS_ORIGIN="$(DOGSWIPE_RELEASE_SPAPS_ORIGIN)" \
		DOGSWIPE_AUTH_REDIRECT_URL="$(DOGSWIPE_RELEASE_AUTH_REDIRECT_URL)" \
		DOGSWIPE_AUTH_UNIVERSAL_LINK_HOSTS="$(DOGSWIPE_RELEASE_AUTH_UNIVERSAL_LINK_HOSTS)" \
		$(IOS_RELEASE_SIGNING_ARGS)

ios-testflight-export: require-ios-archive
	@mkdir -p "$(IOS_RELEASE_EXPORT_PATH)"
	@xcodebuild \
		-exportArchive \
		-archivePath "$(IOS_RELEASE_ARCHIVE_PATH)" \
		-exportPath "$(IOS_RELEASE_EXPORT_PATH)" \
		-exportOptionsPlist "$(IOS_RELEASE_EXPORT_OPTIONS)"

ios-testflight-upload: require-ios-archive require-ios-asc-key
	@xcodebuild \
		-exportArchive \
		-archivePath "$(IOS_RELEASE_ARCHIVE_PATH)" \
		-exportPath "$(IOS_RELEASE_EXPORT_PATH)" \
		-exportOptionsPlist "$(IOS_TESTFLIGHT_UPLOAD_OPTIONS)" \
		-allowProvisioningUpdates \
		-authenticationKeyPath "$(ASC_KEY_PATH)" \
		-authenticationKeyID "$(ASC_KEY_ID)" \
		-authenticationKeyIssuerID "$(ASC_ISSUER_ID)"

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

spaps-app-contract:
	python3 scripts/verify_spaps_app_contract.py
	ALLOW_PLACEHOLDERS=true python3 scripts/render_spaps_registration_payload.py --check
	ALLOW_PLACEHOLDERS=true python3 deploy/render-spaps-origin-handoff.py --check

spaps-registration-payload:
	@ALLOW_PLACEHOLDERS="$(ALLOW_PLACEHOLDERS)" \
	IOS_RELEASE_BUNDLE_ID="$(IOS_RELEASE_BUNDLE_ID)" \
	DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN="$(DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN)" \
	DOGSWIPE_RELEASE_SPAPS_ORIGIN="$(DOGSWIPE_RELEASE_SPAPS_ORIGIN)" \
	DOGSWIPE_RELEASE_AUTH_REDIRECT_URL="$(DOGSWIPE_RELEASE_AUTH_REDIRECT_URL)" \
	DOGSWIPE_RELEASE_AUTH_UNIVERSAL_LINK_HOSTS="$(DOGSWIPE_RELEASE_AUTH_UNIVERSAL_LINK_HOSTS)" \
	python3 scripts/render_spaps_registration_payload.py

spaps-origin-handoff:
	@ALLOW_PLACEHOLDERS="$(ALLOW_PLACEHOLDERS)" \
	SPAPS_APPLICATION_SLUG="$(SPAPS_APPLICATION_SLUG)" \
	DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN="$(DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN)" \
	DOGSWIPE_RELEASE_SPAPS_ORIGIN="$(DOGSWIPE_RELEASE_SPAPS_ORIGIN)" \
	python3 deploy/render-spaps-origin-handoff.py

spaps-origin-handoff-template:
	@tmp="$$(mktemp)"; \
	set -euo pipefail; \
	trap 'rm -f "$$tmp"' EXIT; \
	$(MAKE) --no-print-directory spaps-origin-handoff \
		ALLOW_PLACEHOLDERS=true \
		DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN=dogswipe.example.com >"$$tmp"; \
	grep -q "Application slug: dogswipe" "$$tmp"; \
	grep -q "Required origin:  https://dogswipe.example.com" "$$tmp"; \
	grep -q "UPDATE applications" "$$tmp"; \
	grep -q "make deploy-release-readiness" "$$tmp"; \
	cat "$$tmp"

edge-dry-run:
	$(WRANGLER) deploy --dry-run --config "$(EDGE_WORKER_CONFIG)"

edge-deploy:
	$(WRANGLER) deploy --config "$(EDGE_WORKER_CONFIG)"

edge-verify:
	curl $(EDGE_CURL_RESOLVE_ARG) -fsS "$(EDGE_PUBLIC_HEALTH_URL)" >/dev/null
	curl $(EDGE_CURL_RESOLVE_ARG) -fsS "$(EDGE_PUBLIC_AASA_URL)" | python3 -m json.tool >/dev/null

deploy-config:
	DOGSWIPE_ENV_FILE=prod.env.example DOGSWIPE_IMAGE=dogswipe-api:local POSTGRES_PASSWORD=postgres docker compose --env-file deploy/prod.env.example -f deploy/docker-compose.prod.yml config >/dev/null

deploy-preflight:
	ENV_FILE=deploy/prod.env.example DOGSWIPE_ENV_FILE=prod.env.example DOGSWIPE_IMAGE=dogswipe-api:local POSTGRES_PASSWORD=postgres bash deploy/pre-deploy-checks.sh

deploy-render-aasa:
	@test -n "$(AASA_APPLE_TEAM_ID)" || { \
		echo "AASA_APPLE_TEAM_ID is required. Set it from Apple Developer Team ID."; \
		exit 1; \
	}
	python3 deploy/render-aasa.py --apple-team-id "$(AASA_APPLE_TEAM_ID)" --bundle-id "$(IOS_RELEASE_BUNDLE_ID)" --output "$(AASA_RENDER_PATH)"

deploy-dns-handoff:
	@DOGSWIPE_DNS_ZONE="$(DOGSWIPE_DNS_ZONE)" \
	DOGSWIPE_DNS_TTL="$(DOGSWIPE_DNS_TTL)" \
	DOGSWIPE_EXPECTED_A_RECORD="$(DOGSWIPE_EXPECTED_A_RECORD)" \
	DOGSWIPE_DEPLOY_IP="$(DOGSWIPE_DEPLOY_IP)" \
	bash deploy/render-dns-handoff.sh "$(DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN)"

deploy-dns-handoff-template:
	@tmp="$$(mktemp)"; \
	set -euo pipefail; \
	trap 'rm -f "$$tmp"' EXIT; \
	$(MAKE) --no-print-directory deploy-dns-handoff \
		DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN=dogswipe.example.com \
		DOGSWIPE_EXPECTED_A_RECORD=192.0.2.10 >"$$tmp"; \
	grep -q "Zone:  example.com" "$$tmp"; \
	grep -q "Name:  dogswipe" "$$tmp"; \
	grep -q "Value: 192.0.2.10" "$$tmp"; \
	grep -q "DOGSWIPE_RELEASE_API_BASE_URL=https://dogswipe.example.com" "$$tmp"; \
	grep -q "make deploy-dns-preflight" "$$tmp"; \
	cat "$$tmp"

deploy-dns-preflight:
	@CHECK_PUBLIC_URLS="$(CHECK_PUBLIC_URLS)" \
	DOGSWIPE_EXPECTED_A_RECORD="$(DOGSWIPE_EXPECTED_A_RECORD)" \
	DOGSWIPE_DEPLOY_IP="$(DOGSWIPE_DEPLOY_IP)" \
	PUBLIC_HEALTH_URL="$(PUBLIC_HEALTH_URL)" \
	PUBLIC_AASA_URL="$(PUBLIC_AASA_URL)" \
	bash deploy/dns-preflight.sh "$(DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN)"

deploy-dns-preflight-template:
	@set -euo pipefail; \
	DOGSWIPE_EXPECTED_A_RECORD= bash deploy/dns-preflight.sh example.com; \
	tmp="$$(mktemp)"; \
	if DOGSWIPE_EXPECTED_A_RECORD= bash deploy/dns-preflight.sh dogswipe.invalid >"$$tmp" 2>&1; then \
		cat "$$tmp"; \
		echo "Expected dogswipe.invalid to fail DNS authority"; \
		rm -f "$$tmp"; \
		exit 1; \
	fi; \
	grep -q "DNS zone has no public NS/SOA authority" "$$tmp"; \
	cat "$$tmp"; \
	rm -f "$$tmp"

deploy-live-readiness:
	@ALLOW_PLACEHOLDERS="$(ALLOW_PLACEHOLDERS)" \
	CHECK_ASC_KEY="$(CHECK_ASC_KEY)" \
	CHECK_PUBLIC_URLS="$(CHECK_PUBLIC_URLS)" \
	RUN_DEPLOY_PREFLIGHT="$(RUN_DEPLOY_PREFLIGHT)" \
	RUN_POST_DEPLOY_VERIFY="$(RUN_POST_DEPLOY_VERIFY)" \
	DEPLOY_OVERLAY_FILE="$(DEPLOY_OVERLAY_FILE)" \
	DOGSWIPE_EXPECTED_A_RECORD="$(DOGSWIPE_EXPECTED_A_RECORD)" \
	DOGSWIPE_DEPLOY_IP="$(DOGSWIPE_DEPLOY_IP)" \
	IOS_RELEASE_DEVELOPMENT_TEAM="$(IOS_RELEASE_DEVELOPMENT_TEAM)" \
	IOS_RELEASE_BUNDLE_ID="$(IOS_RELEASE_BUNDLE_ID)" \
	DOGSWIPE_RELEASE_API_BASE_URL="$(DOGSWIPE_RELEASE_API_BASE_URL)" \
	DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN="$(DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN)" \
	DOGSWIPE_RELEASE_SPAPS_API_BASE_URL="$(DOGSWIPE_RELEASE_SPAPS_API_BASE_URL)" \
	DOGSWIPE_RELEASE_SPAPS_PUBLISHABLE_KEY="$(DOGSWIPE_RELEASE_SPAPS_PUBLISHABLE_KEY)" \
	DOGSWIPE_RELEASE_SPAPS_ORIGIN="$(DOGSWIPE_RELEASE_SPAPS_ORIGIN)" \
	DOGSWIPE_RELEASE_AUTH_REDIRECT_URL="$(DOGSWIPE_RELEASE_AUTH_REDIRECT_URL)" \
	DOGSWIPE_RELEASE_AUTH_UNIVERSAL_LINK_HOSTS="$(DOGSWIPE_RELEASE_AUTH_UNIVERSAL_LINK_HOSTS)" \
	ENV_FILE="$(ENV_FILE)" \
	DOGSWIPE_ENV_FILE="$(DOGSWIPE_ENV_FILE)" \
	PUBLIC_HEALTH_URL="$(PUBLIC_HEALTH_URL)" \
	PUBLIC_AASA_URL="$(PUBLIC_AASA_URL)" \
	APPLE_TEAM_ID="$(APPLE_TEAM_ID)" \
	ASC_KEY_PATH="$(ASC_KEY_PATH)" \
	ASC_KEY_ID="$(ASC_KEY_ID)" \
	ASC_ISSUER_ID="$(ASC_ISSUER_ID)" \
	bash deploy/live-readiness.sh

deploy-live-readiness-template:
	@$(MAKE) --no-print-directory deploy-live-readiness \
		ALLOW_PLACEHOLDERS=true \
		DEPLOY_OVERLAY_FILE=deploy/skillbox-overlay.example.yaml \
		IOS_RELEASE_DEVELOPMENT_TEAM=ABCDE12345 \
		DOGSWIPE_RELEASE_API_BASE_URL=https://example.com \
		DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN=example.com \
		DOGSWIPE_RELEASE_SPAPS_PUBLISHABLE_KEY=spaps_pub_example \
		DOGSWIPE_EXPECTED_A_RECORD= \
		RUN_DEPLOY_PREFLIGHT=false \
		RUN_POST_DEPLOY_VERIFY=false

deploy-release-readiness:
	@ALLOW_PLACEHOLDERS="$(ALLOW_PLACEHOLDERS)" \
	CHECK_ASC_KEY="$(CHECK_ASC_KEY)" \
	CHECK_DNS="$(CHECK_DNS)" \
	CHECK_PUBLIC_URLS="$(CHECK_PUBLIC_URLS)" \
	DOGSWIPE_EXPECTED_A_RECORD="$(DOGSWIPE_EXPECTED_A_RECORD)" \
	DOGSWIPE_DEPLOY_IP="$(DOGSWIPE_DEPLOY_IP)" \
	PUBLIC_HEALTH_URL="$(PUBLIC_HEALTH_URL)" \
	PUBLIC_AASA_URL="$(PUBLIC_AASA_URL)" \
	IOS_RELEASE_DEVELOPMENT_TEAM="$(IOS_RELEASE_DEVELOPMENT_TEAM)" \
	IOS_RELEASE_BUNDLE_ID="$(IOS_RELEASE_BUNDLE_ID)" \
	DOGSWIPE_RELEASE_API_BASE_URL="$(DOGSWIPE_RELEASE_API_BASE_URL)" \
	DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN="$(DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN)" \
	DOGSWIPE_RELEASE_SPAPS_API_BASE_URL="$(DOGSWIPE_RELEASE_SPAPS_API_BASE_URL)" \
	DOGSWIPE_RELEASE_SPAPS_PUBLISHABLE_KEY="$(DOGSWIPE_RELEASE_SPAPS_PUBLISHABLE_KEY)" \
	DOGSWIPE_RELEASE_SPAPS_ORIGIN="$(DOGSWIPE_RELEASE_SPAPS_ORIGIN)" \
	DOGSWIPE_RELEASE_AUTH_REDIRECT_URL="$(DOGSWIPE_RELEASE_AUTH_REDIRECT_URL)" \
	DOGSWIPE_RELEASE_AUTH_UNIVERSAL_LINK_HOSTS="$(DOGSWIPE_RELEASE_AUTH_UNIVERSAL_LINK_HOSTS)" \
	ASC_KEY_PATH="$(ASC_KEY_PATH)" \
	ASC_KEY_ID="$(ASC_KEY_ID)" \
	ASC_ISSUER_ID="$(ASC_ISSUER_ID)" \
	bash deploy/release-readiness.sh "$(DEPLOY_OVERLAY_FILE)"

deploy-overlay-template:
	bash deploy/validate-skillbox-overlay.sh deploy/skillbox-overlay.example.yaml --allow-placeholders

deploy-private-handoff-template:
	@tmp="$$(mktemp -d)"; \
	set -euo pipefail; \
	trap 'rm -rf "$$tmp"' EXIT; \
	DOGSWIPE_DEPLOY_SSH=aiops@dogswipe-host \
	DOGSWIPE_DEPLOY_IP=192.0.2.10 \
	DOGSWIPE_DEPLOY_ROOT=/opt/dogswipe \
	DOGSWIPE_ENV_FILE="$$tmp/prod.env" \
	DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN=dogswipe.example.com \
	IOS_RELEASE_DEVELOPMENT_TEAM=ABCDE12345 \
	python3 deploy/render-skillbox-overlay.py --allow-placeholders --output "$$tmp/overlay.yaml"; \
	bash deploy/validate-skillbox-overlay.sh "$$tmp/overlay.yaml" --allow-placeholders; \
	POSTGRES_PASSWORD=replace-me \
	DOGSWIPE_IMAGE=dogswipe-api:local \
	SPAPS_API_URL=https://api.sweetpotato.dev \
	SPAPS_API_KEY=replace-me \
	SPAPS_APPLICATION_ID=00000000-0000-0000-0000-000000000000 \
	DOGSWIPE_ADMIN_USER_IDS=local-admin \
	DOGSWIPE_ENV_FILE="$$tmp/prod.env" \
	DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN=dogswipe.example.com \
	python3 deploy/render-prod-env.py --allow-placeholders --output "$$tmp/prod.env"; \
	ENV_FILE="$$tmp/prod.env" DOGSWIPE_ENV_FILE="$$tmp/prod.env" bash deploy/pre-deploy-checks.sh

deploy-host-bootstrap-template:
	@tmp="$$(mktemp -d)"; \
	set -euo pipefail; \
	trap 'rm -rf "$$tmp"' EXIT; \
	DOGSWIPE_DEPLOY_ROOT="$$tmp/opt/dogswipe" \
	DOGSWIPE_ENV_FILE="$$tmp/opt/envs/dogswipe/prod.env" \
	DOGSWIPE_STORAGE_ROOT="$$tmp/mnt/volume_nyc3_cfo_v1" \
	DOGSWIPE_REVERSE_PROXY_STATIC_ROOT="$$tmp/opt/sweet-potato/deploy/reverse-proxy/static/dogswipe" \
	bash deploy/bootstrap-host.sh --apply; \
	test -f "$$tmp/opt/dogswipe/deploy/docker-compose.prod.yml"; \
	test -f "$$tmp/opt/dogswipe/deploy/pre-deploy-checks.sh"; \
	test -f "$$tmp/opt/dogswipe/deploy/post-deploy-verify.sh"; \
	test -f "$$tmp/opt/dogswipe/deploy/reverse-proxy/dogswipe-api.conf.template"; \
	test -d "$$tmp/opt/envs/dogswipe"; \
	test -d "$$tmp/mnt/volume_nyc3_cfo_v1/dogswipe/pgdata"; \
	test -d "$$tmp/opt/sweet-potato/deploy/reverse-proxy/static/dogswipe"

deploy-post-verify:
	bash deploy/post-deploy-verify.sh
