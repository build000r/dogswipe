SHELL := /bin/bash

PYTHON ?= python3.12
VENV ?= .venv
SKILLS_ROOT ?= ../opensource/skills
CRAP_THRESHOLD ?= 20
PIP := $(VENV)/bin/pip
PYTEST := $(VENV)/bin/pytest
ALEMBIC := $(VENV)/bin/alembic

.PHONY: generate-ios ios-build swift-test backend-install backend-install-local backend-test coverage lint typecheck migrate migration-current test drift crap mmdx-preflight deploy-config deploy-preflight deploy-overlay-template deploy-post-verify

generate-ios:
	cd apps/ios/DogSwipe && xcodegen generate

ios-build: generate-ios
	xcodebuild -project apps/ios/DogSwipe/DogSwipe.xcodeproj -scheme DogSwipe -destination 'generic/platform=iOS' build

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
