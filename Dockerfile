FROM python:3.6-buster as builder
WORKDIR /app
COPY ./haaska/haaska.py .
COPY ./haaska/config/config.json.sample ./config.json
RUN pip install -t . requests pysocks awslambdaric

FROM public.ecr.aws/lambda/python:3.6
#can't test locally without it
ADD https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie /usr/local/bin/aws-lambda-rie
RUN chmod 755 /usr/local/bin/aws-lambda-rie
COPY ./custom_entrypoint /var/runtime/custom_entrypoint
COPY --from=builder /app/ /var/task

# Copy Tailscale binaries from the tailscale image on Docker Hub.
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscaled /var/runtime/tailscaled
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscale /var/runtime/tailscale
RUN mkdir -p /var/run && ln -s /tmp/tailscale /var/run/tailscale && \
  mkdir -p /var/cache && ln -s /tmp/tailscale /var/cache/tailscale && \
  mkdir -p /var/lib && ln -s /tmp/tailscale /var/lib/tailscale && \
  mkdir -p /var/task && ln -s /tmp/tailscale /var/task/tailscale

# Run on container startup.
EXPOSE 8080
ENTRYPOINT ["/var/runtime/custom_entrypoint"]
CMD [ "haaska.event_handler" ]
