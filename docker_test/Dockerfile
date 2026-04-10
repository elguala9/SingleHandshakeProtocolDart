# Dart runtime image for SHSP testing
FROM dart:latest AS builder

# Install system dependencies
RUN apt-get update && apt-get install -y \
    iptables \
    iproute2 \
    iputils-ping \
    curl \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy entire project
COPY . .

# Get dependencies
RUN dart pub get

# Runtime stage
FROM dart:latest

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    iptables \
    iproute2 \
    iputils-ping \
    curl \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy from builder
COPY --from=builder /app /app

# Install pub dependencies in runtime
RUN dart pub get

# Default command
CMD ["/bin/bash"]
