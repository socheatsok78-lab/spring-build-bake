FROM alpine
WORKDIR /src
COPY . .
RUN ls -l 