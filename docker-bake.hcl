variable "JARMODE" {
  default = "layertools"
}
variable "SPRING_BOOT_BAKE_BASE_IMAGE" {
  default = "eclipse-temurin:17-jre-jammy"
}
variable "GRADLE_BUILD_ARTIFACT" {}

target "default" {
  context = BAKE_CMD_CONTEXT
  tags = [
    "demo:latest"
  ]
  dockerfile-inline = <<EOT
# Extract the layers
FROM ${SPRING_BOOT_BAKE_BASE_IMAGE} AS extracted
WORKDIR /extracted
RUN --mount=type=bind,target=/tmp/workdir,rw \
    java -Djarmode=${JARMODE} -jar build/libs/${GRADLE_BUILD_ARTIFACT} extract --destination /extracted

# Final image for the layertools mode
FROM ${SPRING_BOOT_BAKE_BASE_IMAGE} AS final-layertools
ENV SPRING_BOOT_BAKE_APPDIR=${SPRING_BOOT_BAKE_APPDIR}
WORKDIR ${SPRING_BOOT_BAKE_APPDIR}
COPY --from=extracted /extracted/dependencies/ ./
COPY --from=extracted /extracted/spring-boot-loader/ ./
COPY --from=extracted /extracted/snapshot-dependencies/ ./
COPY --from=extracted /extracted/application/ ./

# Final image for the tools mode
FROM ${SPRING_BOOT_BAKE_BASE_IMAGE} AS final-tools
ENV SPRING_BOOT_BAKE_APPDIR=${SPRING_BOOT_BAKE_APPDIR}
ARG GRADLE_BUILD_ARTIFACT
WORKDIR ${SPRING_BOOT_BAKE_APPDIR}
COPY --from=extracted /extracted/lib/ ./
COPY --from=extracted /extracted/${GRADLE_BUILD_ARTIFACT} ./

FROM final-${JARMODE} AS app
EOT
}
