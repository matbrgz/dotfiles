sudo groupadd docker || true
sudo usermod -aG docker "${USER}" || true
docker -H localhost:2375 images
echo "export DOCKER_HOST=\"tcp://0.0.0.0:2375\"" >>"${HOME}"/.bashrc