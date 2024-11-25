# Use an Alpine Linux base image version 3.18 with a specific SHA256 digest for verification  # Utiliza una imagen base de Alpine Linux versión 3.18 con un digest SHA256 específico para verificación
FROM alpine:3.18@sha256:eece025e432126ce23f223450a0326fbebde39cdf496a85d8c016293fc851978

# Add metadata to the image for better identification and documentation  # Agrega metadatos a la imagen para mejor identificación y documentación
LABEL \
  org.label-schema.name="docker-bench-security" \                     
  org.label-schema.url="https://dockerbench.com" \                    
  org.label-schema.vcs-url="https://github.com/docker/docker-bench-security.git" 

# Install required packages without caching to minimize image size  # Instala los paquetes necesarios sin usar caché para minimizar el tamaño de la imagen
RUN apk add --no-cache iproute2 \                                     
    docker-cli \                                                     
    dumb-init \                                                    
    jq                                                               

# Copy all files from the local directory to /usr/local/bin inside the container  # Copia todos los archivos del directorio local a /usr/local/bin dentro del contenedor
COPY . /usr/local/bin/

# Define a health check that always succeeds, as a placeholder  # Define una comprobación de salud que siempre tiene éxito, como marcador de posición
HEALTHCHECK CMD exit 0

# Set the working directory to /usr/local/bin  # Establece el directorio de trabajo en /usr/local/bin
WORKDIR /usr/local/bin

# Set the entrypoint to use dumb-init and run the docker-bench-security script  # Configura el punto de entrada para usar dumb-init y ejecutar el script docker-bench-security
ENTRYPOINT [ "/usr/bin/dumb-init", "/bin/sh", "docker-bench-security.sh" ]
# Set the default command to an empty value  # Est
