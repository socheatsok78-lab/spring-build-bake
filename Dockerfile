ARG SPRING_BOOT_BAKE_BASE_IMAGE=eclipse-temurin:17-jre-alpine

# Extract the Spring Boot layers from the JAR file
FROM ${SPRING_BOOT_BAKE_BASE_IMAGE} AS spring-boot-archive
ARG GRADLE_BUILD_ARTIFACT
WORKDIR /spring-boot-archive
COPY build/libs/${GRADLE_BUILD_ARTIFACT} /${GRADLE_BUILD_ARTIFACT}
RUN java -Djarmode=layertools -jar /${GRADLE_BUILD_ARTIFACT} extract --destination /spring-boot-archive

# Build the final image
FROM ${SPRING_BOOT_BAKE_BASE_IMAGE}

ARG SPRING_BOOT_BAKE_APPDIR="/spring-boot"
ENV SPRING_BOOT_BAKE_APPDIR=${SPRING_BOOT_BAKE_APPDIR}
WORKDIR ${SPRING_BOOT_BAKE_APPDIR}

COPY --from=spring-boot-archive /spring-boot-archive/dependencies/ ./
COPY --from=spring-boot-archive /spring-boot-archive/spring-boot-loader/ ./
COPY --from=spring-boot-archive /spring-boot-archive/snapshot-dependencies/ ./
COPY --from=spring-boot-archive /spring-boot-archive/application/ ./

ARG DOCKERFILE_TEMPLATE=default
ENV DOCKERFILE_TEMPLATE=${DOCKERFILE_TEMPLATE}
