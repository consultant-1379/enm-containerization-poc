# Build the manager binary
FROM golang:1.12.5 as builder

WORKDIR /workspace
# Copy the go source
COPY main.go main.go
COPY api/ api/
COPY keepalived.tmpl keepalived.tmpl
COPY conntrackd.tmpl conntrackd.tmpl
COPY controllers/ controllers/
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum


# Build
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GO111MODULE=on go build -a -o manager main.go

# Use distroless as minimal base image to package the manager binary
# Refer to https://github.com/GoogleContainerTools/distroless for more details
#FROM armdocker.rnd.ericsson.se/proj_oss_releases/enm/lvs-demo:latest
FROM armdocker.rnd.ericsson.se/proj_oss_releases/enm/keepalived:v2.0.16
WORKDIR /
COPY --from=builder /workspace/manager .
COPY --from=builder /workspace/keepalived.tmpl .
COPY --from=builder /workspace/conntrackd.tmpl .
COPY primary-backup.sh .
#RUN yum install -y net-tools netstat tcpdump iproute vim 

ENTRYPOINT ["/manager"]
