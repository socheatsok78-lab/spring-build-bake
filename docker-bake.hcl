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
    java -Djarmode=${JARMODE} -jar /src/build/libs/${GRADLE_BUILD_ARTIFACT} extract --destination /extracted

# Prepare the image for the tools mode
FROM ${SPRING_BOOT_BAKE_BASE_IMAGE} AS jarmode-tools
ENV SPRING_BOOT_BAKE_APPDIR=${SPRING_BOOT_BAKE_APPDIR}
ENV GRADLE_BUILD_ARTIFACT=${GRADLE_BUILD_ARTIFACT}
WORKDIR ${SPRING_BOOT_BAKE_APPDIR}
COPY --from=extracted /extracted/lib/ ${SPRING_BOOT_BAKE_APPDIR}/lib/
COPY --from=extracted /extracted/${GRADLE_BUILD_ARTIFACT} ${SPRING_BOOT_BAKE_APPDIR}
ADD --chmod=0755 https://raw.githubusercontent.com/spring-boot-actions/spring-boot-bake/trunk/docker/tools-entrypoint.sh /java-entrypoint.sh

# Prepare the image for the layertools mode
FROM ${SPRING_BOOT_BAKE_BASE_IMAGE} AS jarmode-layertools
ENV SPRING_BOOT_BAKE_APPDIR=${SPRING_BOOT_BAKE_APPDIR}
WORKDIR ${SPRING_BOOT_BAKE_APPDIR}
COPY --from=extracted /extracted/dependencies/ ${SPRING_BOOT_BAKE_APPDIR}
COPY --from=extracted /extracted/snapshot-dependencies/ ${SPRING_BOOT_BAKE_APPDIR}
COPY --from=extracted /extracted/spring-boot-loader/ ${SPRING_BOOT_BAKE_APPDIR}
COPY --from=extracted /extracted/application/ ${SPRING_BOOT_BAKE_APPDIR}
ADD --chmod=0755 https://raw.githubusercontent.com/spring-boot-actions/spring-boot-bake/trunk/docker/layertools-entrypoint.sh /java-entrypoint.sh

FROM jarmode-${JARMODE} AS app
EOT
}
