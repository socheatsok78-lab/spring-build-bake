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
FROM ${SPRING_BOOT_BAKE_BASE_IMAGE} AS extracted
RUN --mount=type=bind,target=/src,rw \
    java -Djarmode=tools -jar /src/build/libs/${GRADLE_BUILD_ARTIFACT} extract --layers --launcher --destination /extracted

# Prepare the image for the layertools mode
FROM ${SPRING_BOOT_BAKE_BASE_IMAGE}
ENV SPRING_BOOT_BAKE_APPDIR=${SPRING_BOOT_BAKE_APPDIR}
WORKDIR ${SPRING_BOOT_BAKE_APPDIR}
COPY --from=extracted /extracted/dependencies/ ${SPRING_BOOT_BAKE_APPDIR}
COPY --from=extracted /extracted/snapshot-dependencies/ ${SPRING_BOOT_BAKE_APPDIR}
COPY --from=extracted /extracted/spring-boot-loader/ ${SPRING_BOOT_BAKE_APPDIR}
COPY --from=extracted /extracted/application/ ${SPRING_BOOT_BAKE_APPDIR}
EOT
}
