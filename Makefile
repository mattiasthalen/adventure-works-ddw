.PHONY: up down clean restart seed

seed:
	@mkdir -p db/seed/data
	@echo "Downloading Adventure Works CSVs..."
	@cd db/seed/data && \
	for file in $$(gh api repos/NorfolkDataSci/adventure-works-postgres/contents/data --jq '.[].name'); do \
		echo "  $$file"; \
		curl -sL "https://raw.githubusercontent.com/NorfolkDataSci/adventure-works-postgres/master/data/$$file" -o "$$file"; \
	done
	@echo "Done."

up: seed
	docker compose up -d

down:
	docker compose down

clean:
	docker compose down -v

restart: clean up
