REGISTRY=armdocker.rnd.ericsson.se/proj_oss_releases/enm
docker build -t ${REGISTRY}/eric-enm-helmcharts:latest .
docker push ${REGISTRY}/eric-enm-helmcharts:latest
docker run -it --privileged=true -v $(pwd):/tmp/helm/ ${REGISTRY}:/eric-enm-helmcharts:latest

