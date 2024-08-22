FROM nixos/nix:latest AS nix

FROM chainguard/busybox:latest

RUN mkdir -p /etc/ssl/certs
COPY --from=nix /nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-certificates.crt

USER 0

RUN --mount=type=bind,source=.nix-closure,target=nix-closure \
  mkdir -p /nix && cp -R nix-closure /nix/store

RUN --mount=type=bind,source=.result.d,target=result \
  mkdir -p /usr/local/bin && cp result/bin/* /usr/local/bin 

WORKDIR /scripts
RUN chown -R 1001:1001 /scripts
COPY --chown=1001:1001 ./backup.sh ./backup.sh
RUN sed -i "s|#built at#|Built at $(date +'+%r (%Z) on %b %d, %Y')|" ./backup.sh
RUN chmod +x ./backup.sh

SHELL ["bash", "-c"]
ENTRYPOINT ["./backup.sh"]
