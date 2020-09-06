FROM alpine:3.12

COPY . /opt/bash-base
ENTRYPOINT [ "cat", "/opt/bash-base/src/bash-base.sh" ]
