REGISTRY=152254703525.dkr.ecr.eu-west-1.amazonaws.com/eirepoc1-registry
docker build -t aws/rhel6helm .
docker tag aws/rhel6helm ${REGISTRY}:rhel6helm
docker push ${REGISTRY}:rhel6helm
docker run -it --privileged=true -v $(pwd):/tmp/helm/ ${REGISTRY}:rhel6helm
