# ETAPA 1: Construcción (Builder)
# Usamos una imagen con Maven para compilar el código fuente
FROM maven:3.9-eclipse-temurin-17-alpine AS builder
WORKDIR /app

# Optimización de capas: Copiamos solo el pom.xml primero
# Si no hay cambios en las dependencias, Docker usará la caché y compilará más rápido
COPY pom.xml .
RUN mvn dependency:go-offline

# Ahora copiamos el código fuente y compilamos el proyecto
COPY src ./src
RUN mvn clean package -DskipTests

# ETAPA 2: Ejecución (Runtime)
# Usamos una imagen más ligera solo con el entorno de ejecución de Java
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Seguridad: Creamos y asignamos un usuario no root para ejecutar la aplicación
RUN addgroup -S springgroup && adduser -S springuser -G springgroup
USER springuser

# TRUCO DEL NOMBRE: Copiamos el .jar generado desde la etapa "builder".
# Al usar *.jar, no importa si tu microservicio se llama BFF u Orchestrator en el pom.xml,
# Docker tomará el archivo generado y lo renombrará internamente a "app.jar".
COPY --from=builder /app/target/*.jar app.jar

# Exponemos el puerto.
EXPOSE 8082

# Comando de inicio del contenedor
ENTRYPOINT ["java", "-jar", "app.jar"]