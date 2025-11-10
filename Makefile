validate-secrets: ## Validate .env secrets
	@if [ -f scripts/validate-secrets.sh ]; then \
		./scripts/validate-secrets.sh; \
	else \
		echo "Warning: validate-secrets.sh not found. Skipping."; \
	fi