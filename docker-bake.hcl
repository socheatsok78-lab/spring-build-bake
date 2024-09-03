variable "GRADLE_BUILD_ARTIFACT" {}
variable "GRADLE_BUILD_ARTIFACT_ID" {}

variable "SPRING_BOOT_BAKE_BASE_IMAGE" {
  default = "eclipse-temurin:17-jre-jammy"
}
variable "SPRING_BOOT_BAKE_APPDIR" {
  default = "/app"
}
variable "JARMODE" {
  default = "layertools"
}

target "default" {
  context = BAKE_CMD_CONTEXT
  dockerfile-inline = <<EOT
# Extract the layers
FROM ${SPRING_BOOT_BAKE_BASE_IMAGE} AS app
RUN --mount=type=bind,target=/src,rw \
    java -Djarmode=${JARMODE} -jar /src/build/libs/${GRADLE_BUILD_ARTIFACT} extract --destination /app

# Final image for the layertools mode
FROM ${SPRING_BOOT_BAKE_BASE_IMAGE} AS final-layertools
ENV SPRING_BOOT_BAKE_APPDIR=${SPRING_BOOT_BAKE_APPDIR}
WORKDIR ${SPRING_BOOT_BAKE_APPDIR}
COPY --from=app /app/dependencies/ ${SPRING_BOOT_BAKE_APPDIR}/dependencies/
COPY --from=app /app/snapshot-dependencies/ ${SPRING_BOOT_BAKE_APPDIR}/snapshot-dependencies/
COPY --from=app /app/spring-boot-loader/ ${SPRING_BOOT_BAKE_APPDIR}/spring-boot-loader/
COPY --from=app /app/application/ ${SPRING_BOOT_BAKE_APPDIR}/application/

# Final image for the tools mode
FROM ${SPRING_BOOT_BAKE_BASE_IMAGE} AS final-tools
ENV SPRING_BOOT_BAKE_APPDIR=${SPRING_BOOT_BAKE_APPDIR}
ENV GRADLE_BUILD_ARTIFACT=${GRADLE_BUILD_ARTIFACT}
WORKDIR ${SPRING_BOOT_BAKE_APPDIR}
COPY --from=app /app/lib/ ${SPRING_BOOT_BAKE_APPDIR}/lib/
COPY --from=app /app/${GRADLE_BUILD_ARTIFACT} ${SPRING_BOOT_BAKE_APPDIR}/

FROM final-${JARMODE} AS app
EOT
}
