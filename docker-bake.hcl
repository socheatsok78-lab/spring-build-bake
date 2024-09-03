target "default" {
  context = BAKE_CMD_CONTEXT
  dockerfile = "Dockerfile"
}
target "default" {
  context = BAKE_CMD_CONTEXT
  dockerfile-inline = <<EOT
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
RUN --mount=type=bind,target=/app,rw java -Djarmode=tools -jar build/libs/demo-0.0.1-SNAPSHOT.jar extract --destination /tmp/extracted
EOT
}
