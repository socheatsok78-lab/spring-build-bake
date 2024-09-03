target "default" {
  context = BAKE_CMD_CONTEXT
  dockerfile = "Dockerfile"
}
target "default" {
  context = BAKE_CMD_CONTEXT
  dockerfile-inline = <<EOT
FROM alpine
RUN --mount=type=bind ls -la
EOT
}