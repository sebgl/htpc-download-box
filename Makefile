plex-update:
	docker-compose down
	docker-compose pull
	docker-compose up -d
	docker image prune -f
.PHONY: plex-update