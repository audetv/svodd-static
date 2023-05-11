build:
	docker --log-level=debug build --pull --file=docker/production/nginx/Dockerfile --tag=${REGISTRY}/svodd-static:${IMAGE_TAG} .
push:
	docker push ${REGISTRY}/svodd-static:${IMAGE_TAG}

try-build:
	REGISTRY=localhost IMAGE_TAG=0 make build

deploy:
	ssh -o StrictHostKeyChecking=no deploy@${HOST} -p ${PORT} 'docker network create --driver=overlay svodd-static || true'
	ssh -o StrictHostKeyChecking=no deploy@${HOST} -p ${PORT} 'rm -rf svodd-static_${BUILD_NUMBER} && mkdir svodd-static_${BUILD_NUMBER}'

	envsubst < docker-compose-production.yml > docker-compose-production-env.yml
	scp -o StrictHostKeyChecking=no -P ${PORT} docker-compose-production-env.yml deploy@${HOST}:svodd-static_${BUILD_NUMBER}/docker-compose.yml
	rm -f docker-compose-production-env.yml

	ssh -o StrictHostKeyChecking=no deploy@${HOST} -p ${PORT} 'cd svodd-static_${BUILD_NUMBER} && docker stack deploy --compose-file docker-compose.yml svodd-static --with-registry-auth --prune'
