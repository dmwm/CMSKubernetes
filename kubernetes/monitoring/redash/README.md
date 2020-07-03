convert docker compose file into k8s manifest files
https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/
or use docker stack deploy
https://www.docker.com/blog/simplifying-kubernetes-with-docker-compose-and-friends/

The generated k8s yaml files may contain passwords, etc. Therefore, we need
to crate a new secret yaml file and replace our sensitive info in all
k8s yaml files to use them from secret file, see
https://www.digitalocean.com/community/tutorials/how-to-migrate-a-docker-compose-workflow-to-kubernetes
So, basically we need to replace sensitive value with
          valueFrom:
            secretKeyRef:
              name: redash-secret
              key: SOME_PASSWORD

The redis service does not work yet and therefore no redash access is possible.
See,
https://stackoverflow.com/questions/48597726/connection-refused-error-when-connecting-to-kubernetes-redis-service/48608269#48608269
https://redis.io/topics/config

Order of deployment (we probably need to add initContainer to allow services to
start out of order):
postgres pvc
postgres
redis
server
scheduler
scheduled-worker
adhoc-worker
