PYTHON ?= python3.12
VENV ?= .venv
SKILLS_ROOT ?= ../opensource/skills
PIP := $(VENV)/bin/pip
PYTEST := $(VENV)/bin/pytest
ALEMBIC := $(VENV)/bin/alembic

.PHONY: generate-ios ios-build swift-test backend-install backend-install-local backend-test coverage lint typecheck migrate migration-current test drift crap deploy-config deploy-preflight deploy-overlay-template deploy-post-verify

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

crap:
	python3 $(SKILLS_ROOT)/crap/scripts/analyze_crap.py $(CURDIR) --languages python,swift --threshold 20 --top 20

deploy-config:
	DOGSWIPE_ENV_FILE=prod.env.example DOGSWIPE_IMAGE=dogswipe-api:local POSTGRES_PASSWORD=postgres docker compose --env-file deploy/prod.env.example -f deploy/docker-compose.prod.yml config >/dev/null

deploy-preflight:
	ENV_FILE=deploy/prod.env.example DOGSWIPE_ENV_FILE=prod.env.example DOGSWIPE_IMAGE=dogswipe-api:local POSTGRES_PASSWORD=postgres bash deploy/pre-deploy-checks.sh

deploy-overlay-template:
	bash deploy/validate-skillbox-overlay.sh deploy/skillbox-overlay.example.yaml --allow-placeholders

deploy-post-verify:
	bash deploy/post-deploy-verify.sh
