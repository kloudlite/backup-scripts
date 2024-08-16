FROM nixos/nix:latest AS nix

FROM busybox:latest

RUN mkdir -p /etc/ssl/certs
COPY --from=nix /nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-certificates.crt

WORKDIR /scripts
# RUN --mount=type=bind,source=nix-closure,target=nix-closure \
#   mkdir -p /nix && cp -R nix-closure /nix/store && \
#   mkdir -p /usr/local/bin && mv result/bin/* /usr/local/bin/ && rm -rf result

RUN --mount=type=bind,source=nix-closure,target=nix-closure \
  mkdir -p /nix && cp -R nix-closure /nix/store

RUN --mount=type=bind,source=result.d,target=result \
  mkdir -p /usr/local/bin && cp result/bin/* /usr/local/bin 

COPY ./backup.sh ./backup.sh
