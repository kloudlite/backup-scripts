FROM nixos/nix:latest AS nix

FROM chainguard/busybox:latest
# FROM scratch

WORKDIR /etc/ssl/certs
# RUN mkdir -p /etc/ssl/certs
COPY --from=nix /nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-certificates.crt

# RUN --mount=type=bind,source=nix-closure,target=nix-closure \
#   mkdir -p /nix && cp -R nix-closure /nix/store && \
#   mkdir -p /usr/local/bin && mv result/bin/* /usr/local/bin/ && rm -rf result
WORKDIR /nix

RUN --mount=type=bind,source=.nix-closure,target=nix-closure \
  cp -R nix-closure /nix/store
# mkdir -p /nix && cp -R nix-closure /nix/store

WORKDIR /usr/local/bin
RUN --mount=type=bind,source=.result.d,target=result \
  cp result/bin/* /usr/local/bin 
# mkdir -p /usr/local/bin && cp result/bin/* /usr/local/bin 

WORKDIR /scripts
USER 0
RUN chown -R 1001:1001 /scripts

USER 1001:1001
COPY ./backup.sh ./backup.sh
RUN chmod +x ./backup.sh

SHELL ["bash", "-c"]
ENTRYPOINT ["./backup.sh"]
