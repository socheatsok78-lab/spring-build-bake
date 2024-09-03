variable "GRADLE_BUILD_ARTIFACT" {}

variable "JARMODE" {
  default = "layertools"
}
variable "SPRING_BOOT_BAKE_BASE_IMAGE" {
  default = "eclipse-temurin:17-jre-jammy"
}
variable "SPRING_BOOT_BAKE_APPDIR" {
  default = "/app"
}

target "default" {
  context = BAKE_CMD_CONTEXT
  tags = [
    "demo:latest"
  ]
  dockerfile-inline = <<EOT
# Extract the layers
FROM ${SPRING_BOOT_BAKE_BASE_IMAGE} AS extracted
RUN --mount=type=bind,target=/tmp/workdir,rw \
    java -Djarmode=${JARMODE} -jar /tmp/workdir/build/libs/${GRADLE_BUILD_ARTIFACT} extract --destination /extracted

# Final image for the layertools mode
FROM ${SPRING_BOOT_BAKE_BASE_IMAGE} AS final-layertools
ENV SPRING_BOOT_BAKE_APPDIR=${SPRING_BOOT_BAKE_APPDIR}
WORKDIR ${SPRING_BOOT_BAKE_APPDIR}
COPY --from=extracted /extracted/dependencies/ ${SPRING_BOOT_BAKE_APPDIR}/dependencies/
COPY --from=extracted /extracted/snapshot-dependencies/ ${SPRING_BOOT_BAKE_APPDIR}/snapshot-dependencies/
COPY --from=extracted /extracted/spring-boot-loader/ ${SPRING_BOOT_BAKE_APPDIR}/spring-boot-loader/
COPY --from=extracted /extracted/application/ ${SPRING_BOOT_BAKE_APPDIR}/application/ß

# Final image for the tools mode
FROM ${SPRING_BOOT_BAKE_BASE_IMAGE} AS final-tools
ENV SPRING_BOOT_BAKE_APPDIR=${SPRING_BOOT_BAKE_APPDIR}
ARG GRADLE_BUILD_ARTIFACT
WORKDIR ${SPRING_BOOT_BAKE_APPDIR}
COPY --from=extracted /extracted/lib/ ${SPRING_BOOT_BAKE_APPDIR}/lib/
COPY --from=extracted /extracted/${GRADLE_BUILD_ARTIFACT} ${SPRING_BOOT_BAKE_APPDIR}/

FROM final-${JARMODE} AS app
EOT
}
