FROM node:19.7.0-alpine as nodejs-builder
RUN apk add make git
RUN git clone https://github.com/prymitive/karma.git
RUN mkdir -p /src/ui
RUN cp karma/ui/package.json karma/ui/package-lock.json /src/ui/
RUN cd /src/ui && npm ci && touch node_modules/.install
RUN apk add make git
RUN cp -R karma/ui /src
RUN make -C /src/ui build

FROM golang:1.20.2-alpine as go-builder
RUN apk add make git
RUN git clone https://github.com/prymitive/karma.git
RUN mkdir -p /src
RUN cp karma/Makefile /src/Makefile
RUN cp -R karma/make /src/make
RUN cp karma/go.mod /src/go.mod
RUN cp karma/go.sum /src/go.sum
RUN make -C /src download-deps-go
COPY --from=nodejs-builder /src/ui/src /src/ui/src
COPY --from=nodejs-builder /src/ui/build /src/ui/build
COPY --from=nodejs-builder /src/ui/mock /src/ui/mock
COPY --from=nodejs-builder /src/ui/embed.go /src/ui/embed.go
RUN cp -R karma/cmd /src/cmd
RUN cp -R karma/internal /src/internal
ARG VERSION
RUN CGO_ENABLED=0 make -C /src VERSION="${VERSION:-dev}" karma

FROM gcr.io/distroless/base
COPY --from=go-builder /src/karma /karma
COPY karma.yaml /karma.yaml
EXPOSE 8080
ENTRYPOINT ["/karma"]
