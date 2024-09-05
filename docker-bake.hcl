variable "JARMODE" {
  default = "tools"
}
variable "GRADLE_BUILD_ARTIFACT" {}
variable "GRADLE_BUILD_ARTIFACT_ID" {}
variable "SPRING_BOOT_BAKE_BASE_IMAGE" {
  default = "eclipse-temurin:17-jre-jammy"
}
variable "SPRING_BOOT_BAKE_APPDIR" {
  default = "/app"
}

target "default" {
  context = BAKE_CMD_CONTEXT
  dockerfile-inline = <<EOT
# Extract Spring Boot application layers using jarmode=tools
FROM ${SPRING_BOOT_BAKE_BASE_IMAGE} AS jarmode-tools
ARG SPRING_BOOT_BAKE_APPDIR
ARG GRADLE_BUILD_ARTIFACT
RUN --mount=type=bind,target=/src,rw \
    java -Djarmode=tools -jar /src/build/libs/${GRADLE_BUILD_ARTIFACT} extract --layers --launcher --destination ${SPRING_BOOT_BAKE_APPDIR}

# Extract Spring Boot application layers using jarmode=layertools
# Note: the jarmode=layertools is being deprecated in favor of jarmode=tools
FROM ${SPRING_BOOT_BAKE_BASE_IMAGE} AS jarmode-layertools
ARG SPRING_BOOT_BAKE_APPDIR
ARG GRADLE_BUILD_ARTIFACT
RUN --mount=type=bind,target=/src,rw \
    java -Djarmode=layertools -jar /src/build/libs/${GRADLE_BUILD_ARTIFACT} extract --destination ${SPRING_BOOT_BAKE_APPDIR}

# Intermediate layer to extract the layers using the specified jarmode
FROM layered-${JARMODE} AS layered

# Final image with the Spring Boot application layers
FROM jarmode-${JARMODE}
ARG GRADLE_BUILD_ARTIFACT
ENV GRADLE_BUILD_ARTIFACT=${GRADLE_BUILD_ARTIFACT}
ARG SPRING_BOOT_BAKE_APPDIR
ENV SPRING_BOOT_BAKE_APPDIR=${SPRING_BOOT_BAKE_APPDIR}
WORKDIR ${SPRING_BOOT_BAKE_APPDIR}
COPY --from=layered ${SPRING_BOOT_BAKE_APPDIR}/dependencies/ ${SPRING_BOOT_BAKE_APPDIR}
COPY --from=layered ${SPRING_BOOT_BAKE_APPDIR}/spring-boot-loader/ ${SPRING_BOOT_BAKE_APPDIR}
COPY --from=layered ${SPRING_BOOT_BAKE_APPDIR}/snapshot-dependencies/ ${SPRING_BOOT_BAKE_APPDIR}
COPY --from=layered ${SPRING_BOOT_BAKE_APPDIR}/application/ ${SPRING_BOOT_BAKE_APPDIR}
ADD --chmod=0755 https://raw.githubusercontent.com/spring-boot-actions/spring-boot-bake/v4/docker/java-entrypoint.sh /java-entrypoint.sh
EOT
}
