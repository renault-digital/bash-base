FROM alpine:3.12
COPY scripts/verify-by-spec.sh LICENSE CHANGELOG.md README.md CODE_OF_CONDUCT.md CONTRIBUTING.md /opt/bash-base/
COPY docs /opt/bash-base/docs
COPY man /opt/bash-base/man
COPY spec /opt/bash-base/spec
COPY src /opt/bash-base/bin
ENTRYPOINT [ "cat", "/opt/bash-base/bin/bash-base.sh" ]
