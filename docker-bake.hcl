target "default" {
  context = BAKE_CMD_CONTEXT
  dockerfile = "Dockerfile"
}
target "default" {
  context = BAKE_CMD_CONTEXT
  dockerfile-inline = <<EOT
FROM alpine
RUN --mount=type=bind,target=/app,source=.,rw ls -la
EOT
}
