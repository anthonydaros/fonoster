#!/bin/bash
# Script para configurar o Fonoster seguindo a documentação oficial
# https://docs.fonoster.com/self-hosting/deploy-with-docker

set -e

echo "Configurando o Fonoster na VPS 103.199.185.165"

# Passo 1: Criar a estrutura de diretórios
mkdir -p config/keys

# Passo 2: Gerar chaves para autenticação
echo "Gerando chaves para autenticação"
openssl genrsa -out config/keys/private.pem 4096
openssl rsa -in config/keys/private.pem -pubout -out config/keys/public.pem

# Passo 3: Configurar permissões corretas
chmod 600 config/keys/private.pem
chmod 644 config/keys/public.pem

# Passo 4: Criar arquivo de integrações
cat > config/integrations.json << 'EOF'
{
  "assistants": {},
  "callManagers": [],
  "channels": [],
  "fonos": {},
  "providers": {
    "api": {
      "baseUrl": "https://api.fonoster.io/v1",
      "type": "api"
    }
  }
}
EOF

# Passo 5: Usar o docker-compose.yml da documentação oficial
cat > docker-compose.yml << 'EOF'
services:
  apiserver:
    image: fonoster/apiserver:latest
    restart: unless-stopped
    environment:
      - APISERVER_APP_URL
      - APISERVER_ASTERISK_ARI_PROXY_URL
      - APISERVER_ASTERISK_ARI_SECRET
      - APISERVER_ASTERISK_ARI_USERNAME
      - APISERVER_AUTHZ_SERVICE_ENABLED
      - APISERVER_AUTHZ_SERVICE_HOST
      - APISERVER_AUTHZ_SERVICE_METHODS
      - APISERVER_AUTHZ_SERVICE_PORT
      - APISERVER_CLOAK_ENCRYPTION_KEY
      - APISERVER_DATABASE_URL
      - APISERVER_IDENTITY_DATABASE_URL
      - APISERVER_IDENTITY_ISSUER
      - APISERVER_IDENTITY_CONTACT_VERIFICATION_REQUIRED
      - APISERVER_IDENTITY_TWO_FACTOR_AUTHENTICATION_REQUIRED
      - APISERVER_IDENTITY_WORKSPACE_INVITE_EXPIRATION
      - APISERVER_IDENTITY_WORKSPACE_INVITE_FAIL_URL
      - APISERVER_IDENTITY_WORKSPACE_INVITE_URL
      - APISERVER_IDENTITY_RESET_PASSWORD_URL
      - APISERVER_INFLUXDB_INIT_ORG
      - APISERVER_INFLUXDB_INIT_PASSWORD
      - APISERVER_INFLUXDB_INIT_TOKEN
      - APISERVER_INFLUXDB_INIT_USERNAME
      - APISERVER_INFLUXDB_URL
      - APISERVER_LOGS_FORMAT
      - APISERVER_LOGS_LEVEL
      - APISERVER_LOGS_TRANSPORT
      - APISERVER_NATS_URL
      - APISERVER_OWNER_EMAIL
      - APISERVER_OWNER_NAME
      - APISERVER_OWNER_PASSWORD
      - APISERVER_SMTP_AUTH_PASS
      - APISERVER_SMTP_AUTH_USER
      - APISERVER_SMTP_HOST
      - APISERVER_SMTP_PORT
      - APISERVER_SMTP_SECURE
      - APISERVER_SMTP_SENDER
      - APISERVER_TWILIO_ACCOUNT_SID
      - APISERVER_TWILIO_AUTH_TOKEN
      - APISERVER_TWILIO_PHONE_NUMBER
    ports:
      - 50051:50051
    volumes:
      - ./config/keys:/opt/fonoster/keys:ro
      - ./config/integrations.json:/opt/fonoster/integrations.json:ro

  autopilot:
    image: fonoster/autopilot:latest
    restart: unless-stopped
    ports:
      - 50061:50061
    environment:
      - AUTOPILOT_AWS_S3_ACCESS_KEY_ID
      - AUTOPILOT_AWS_S3_ENDPOINT
      - AUTOPILOT_AWS_S3_REGION
      - AUTOPILOT_AWS_S3_SECRET_ACCESS_KEY
      - AUTOPILOT_CONVERSATION_PROVIDER
      - AUTOPILOT_KNOWLEDGE_BASE_ENABLED
      - AUTOPILOT_LOGS_FORMAT
      - AUTOPILOT_LOGS_LEVEL
      - AUTOPILOT_LOGS_TRANSPORT
      - AUTOPILOT_OPENAI_API_KEY
      - AUTOPILOT_UNSTRUCTURED_API_KEY
      - AUTOPILOT_UNSTRUCTURED_API_URL
    volumes:
      - ./config/integrations.json:/opt/fonoster/integrations.json:ro

  routr:
    image: fonoster/routr-one:latest
    restart: unless-stopped
    environment:
      DATABASE_URL: ${ROUTR_DATABASE_URL}
      EXTERNAL_ADDRS: ${ROUTR_EXTERNAL_ADDRS}
      LOGS_FORMAT: ${ROUTR_LOGS_FORMAT}
      LOGS_LEVEL: ${ROUTR_LOGS_LEVEL}
      LOGS_TRANSPORT: ${ROUTR_LOGS_TRANSPORT}
      NATS_PUBLISHER_ENABLED: true
      NATS_PUBLISHER_URL: ${ROUTR_NATS_PUBLISHER_URL}
      RTPENGINE_HOST: ${ROUTR_RTPENGINE_HOST}
      START_INTERNAL_DB: "false"
    ports:
      - 51907:51907
      - 51908:51908
      - 5060:5060/udp
      - 5060-5063:5060-5063

  rtpengine:
    image: fonoster/rtpengine:latest
    restart: unless-stopped
    platform: linux/x86_64
    ports: 
      - 10000-10100:10000-10100/udp
      - 8081:8080
    environment:
      PORT_MAX: ${RTPENGINE_PORT_MAX}
      PORT_MIN: ${RTPENGINE_PORT_MIN}
      PUBLIC_IP: ${RTPENGINE_PUBLIC_IP}

  asterisk:
    image: fonoster/asterisk:latest
    restart: unless-stopped
    environment:
      ARI_PROXY_URL: ${ASTERISK_ARI_PROXY_URL}
      ARI_SECRET: ${ASTERISK_ARI_SECRET}
      ARI_USERNAME: ${ASTERISK_ARI_USERNAME}
      CODECS: ${ASTERISK_CODECS}
      DTMF_MODE: ${ASTERISK_DTMF_MODE}
      RTP_PORT_END: ${ASTERISK_RTP_PORT_END}
      RTP_PORT_START: ${ASTERISK_RTP_PORT_START}
      SIPPROXY_HOST: ${ASTERISK_SIPPROXY_HOST}
      SIPPROXY_PORT: ${ASTERISK_SIPPROXY_PORT}
      SIPPROXY_SECRET: ${ASTERISK_SIPPROXY_SECRET}
      SIPPROXY_USERNAME: ${ASTERISK_SIPPROXY_USERNAME}
    ports:
      - 6060:6060
      - 8088:8088

  postgres:
    image: postgres:16.2-alpine
    restart: unless-stopped
    environment:
      PGTZ: UTC
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_USER: ${POSTGRES_USER}
      TZ: UTC
    ports:
      - 5432:5432
    volumes:
      - db:/var/lib/postgresql/data

  influxdb:
    image: influxdb:2
    restart: unless-stopped
    ports:
      - 8086:8086
    environment:
      DOCKER_INFLUXDB_INIT_ADMIN_TOKEN: ${INFLUXDB_INIT_TOKEN}
      DOCKER_INFLUXDB_INIT_BUCKET: calls
      DOCKER_INFLUXDB_INIT_MODE: setup
      DOCKER_INFLUXDB_INIT_ORG: ${INFLUXDB_INIT_ORG}
      DOCKER_INFLUXDB_INIT_PASSWORD: ${INFLUXDB_INIT_PASSWORD}
      DOCKER_INFLUXDB_INIT_USERNAME: ${INFLUXDB_INIT_USERNAME}
    volumes:
      - influxdb:/var/lib/influxdb2

  nats:
    image: nats:latest
    restart: unless-stopped
    ports:
      - 4222:4222

  envoy:
    image: envoyproxy/envoy:v1.31.0
    restart: unless-stopped
    volumes:
      - ./config/envoy.yaml:/etc/envoy/envoy.yaml:ro
    ports:
      - 8449:8449

  webui:
    image: fonoster/webui:latest
    restart: unless-stopped
    environment:
      - REACT_APP_API_URL=http://103.199.185.165:8449
    ports:
      - 8282:80

  adminer:
    image: adminer:latest
    restart: unless-stopped
    environment:
      ADMINER_DEFAULT_SERVER: postgres
    ports:
      - 8283:8080

volumes:
  db:
  influxdb:
EOF

# Passo 6: Criar o env file usando o .env.example como base e atualizando para a instalação atual
cat > .env << 'EOF'
# General Notes
# -------------
#
# You must set the following variables to the IP address of the host machine:
#
# - ROUTR_EXTERNAL_ADDRS
# - ROUTR_RTPENGINE_HOST
# - ASTERISK_SIPPROXY_HOST
#
# Note: If you are running in a cloud environment, this will be the public IP address of your server.
# If you are running locally, this will be the IP address of your local machine.
#
# Please ensure you change the default secrets for all services in production environments.
# 
# Secrets (create strong passwords):
# 
# - APISERVER_ASTERISK_ARI_SECRET
# - APISERVER_OWNER_PASSWORD
# - APISERVER_INFLUXDB_INIT_PASSWORD
# - ASTERISK_SIPPROXY_SECRET
# - ASTERISK_ARI_SECRET
# - POSTGRES_PASSWORD
# - APISERVER_DATABASE_URL (which includes the database password)
# - APISERVER_IDENTITY_DATABASE_URL (which includes the database password)

# API Server Settings
# ------------------
# The owner email and password are used to create the initial administrator user.
# The server will create a new owner if the email does not exist.
# The password will be updated if the email already exists.
APISERVER_APP_URL=http://103.199.185.165:8282
APISERVER_ASTERISK_ARI_PROXY_URL=http://asterisk:8088   
APISERVER_ASTERISK_ARI_SECRET=Fonoster@ARI2025!
APISERVER_ASTERISK_ARI_USERNAME=ari
APISERVER_AUTHZ_SERVICE_ENABLED=false
APISERVER_AUTHZ_SERVICE_HOST=fnauthz
APISERVER_AUTHZ_SERVICE_METHODS=/fonoster.calls.v1beta2.Calls/CreateCall,/fonoster.identity.v1beta2.Identity/CreateWorkspace
APISERVER_AUTHZ_SERVICE_PORT=50071
APISERVER_CLOAK_ENCRYPTION_KEY=k1.aesgcm256.MmPSvzCG9fk654bAbl30tsqq4h9d3N4F11hlue8bGAY=
APISERVER_DATABASE_URL=postgresql://postgres:PostgreSQL@2025!@postgres:5432/fonoster
APISERVER_IDENTITY_DATABASE_URL=postgresql://postgres:PostgreSQL@2025!@postgres:5432/fnidentity
APISERVER_IDENTITY_ISSUER=http://103.199.185.165:8449
APISERVER_IDENTITY_OAUTH2_GITHUB_CLIENT_ID=
APISERVER_IDENTITY_OAUTH2_GITHUB_CLIENT_SECRET=
APISERVER_IDENTITY_OAUTH2_GITHUB_ENABLED=false
APISERVER_IDENTITY_WORKSPACE_INVITE_FAIL_URL=http://103.199.185.165:8282/invite-fail
APISERVER_IDENTITY_WORKSPACE_INVITE_URL=http://103.199.185.165:8449/api/identity/accept-invite
APISERVER_IDENTITY_RESET_PASSWORD_URL=http://103.199.185.165:8449/api/identity/reset-password
APISERVER_IDENTITY_WORKSPACE_INVITE_EXPIRATION=1d
APISERVER_IDENTITY_CONTACT_VERIFICATION_REQUIRED=false
APISERVER_IDENTITY_TWO_FACTOR_AUTHENTICATION_REQUIRED=false
APISERVER_INFLUXDB_INIT_ORG=fonoster
APISERVER_INFLUXDB_INIT_PASSWORD=InfluxDB@Secure2025!
APISERVER_INFLUXDB_INIT_TOKEN=ghjNQ59FW4oi3bAiMTtfMyVnqtbwq0Iib58D63Lgk3pcrEFFPT0d9tnRKzHk98HNqZJUPc_mpXVkk07_JhBhJg==
APISERVER_INFLUXDB_INIT_USERNAME=influxdb
APISERVER_INFLUXDB_URL=http://influxdb:8086
APISERVER_LOGS_FORMAT=json
APISERVER_LOGS_LEVEL=verbose
APISERVER_LOGS_TRANSPORT=none
APISERVER_NATS_URL=nats://nats:4222
APISERVER_OWNER_EMAIL=admin@fonoster.local
APISERVER_OWNER_NAME=Admin User
APISERVER_OWNER_PASSWORD=SuperSecureAdmin2025!
APISERVER_ROOT_DOMAIN=fonoster.local
APISERVER_SMTP_AUTH_PASS=secret
APISERVER_SMTP_AUTH_USER=postmaster@fonoster.local
APISERVER_SMTP_HOST=your-smtp-server
APISERVER_SMTP_PORT=587
APISERVER_SMTP_SECURE=true
APISERVER_SMTP_SENDER="Fonoster Info <info@fonoster.local>"
APISERVER_TWILIO_ACCOUNT_SID=
APISERVER_TWILIO_AUTH_TOKEN=
APISERVER_TWILIO_PHONE_NUMBER=

# Autopilot Settings
# -----------------
# The Knowledge Base feature requires an S3-compatible storage service.
# OpenAI API and Unstructured API keys are also required to enable this feature.
#
# The Knowledge Base feature is disabled by default due to its multiple integrations.
# Please consult the documentation for details on how to enable it.
AUTOPILOT_AWS_S3_ACCESS_KEY_ID=
AUTOPILOT_AWS_S3_ENDPOINT=
AUTOPILOT_AWS_S3_REGION=
AUTOPILOT_AWS_S3_SECRET_ACCESS_KEY=
AUTOPILOT_CONVERSATION_PROVIDER=api
AUTOPILOT_INTEGRATIONS_FILE=/opt/fonoster/integrations.json
AUTOPILOT_KNOWLEDGE_BASE_ENABLED=false
AUTOPILOT_LOGS_FORMAT=none
AUTOPILOT_LOGS_LEVEL=verbose
AUTOPILOT_LOGS_TRANSPORT=none
AUTOPILOT_OPENAI_API_KEY=
AUTOPILOT_UNSTRUCTURED_API_KEY=
AUTOPILOT_UNSTRUCTURED_API_URL=

# Routr Settings
# -------------
# The external address must be configured to an address accessible by all endpoints.
# For local network deployments, this is typically your router's public IP address.
# For cloud deployments, this is typically the public IP address of your cloud instance.
ROUTR_DATABASE_URL=postgresql://postgres:PostgreSQL@2025!@postgres:5432/routr
ROUTR_EXTERNAL_ADDRS=103.199.185.165
ROUTR_LOGS_FORMAT=none
ROUTR_LOGS_LEVEL=verbose
ROUTR_LOGS_TRANSPORT=none
ROUTR_NATS_PUBLISHER_ENABLED=true
ROUTR_NATS_PUBLISHER_URL=nats://nats:4222
ROUTR_RTPENGINE_HOST=rtpengine

# Asterisk Settings
# ----------------
# Note: Set ASTERISK_SIPPROXY_HOST to the same value as ROUTR_EXTERNAL_ADDRS
ASTERISK_ARI_PROXY_URL=http://asterisk:8088
ASTERISK_ARI_SECRET=Fonoster@ARI2025!
ASTERISK_ARI_USERNAME=ari
ASTERISK_CODECS=g722,ulaw,alaw
ASTERISK_DTMF_MODE=auto_info
ASTERISK_RTP_PORT_END=20000
ASTERISK_RTP_PORT_START=10000
ASTERISK_SIPPROXY_HOST=103.199.185.165
ASTERISK_SIPPROXY_PORT=5060
ASTERISK_SIPPROXY_SECRET=SIPproxy@2025!
ASTERISK_SIPPROXY_USERNAME=voice

# RTP Engine Settings
# ------------------
# Set RTPENGINE_PUBLIC_IP to the same value as ROUTR_EXTERNAL_ADDRS
# Adjust RTPENGINE_PORT_MIN and RTPENGINE_PORT_MAX to define the range for media traffic.
RTPENGINE_PORT_MAX=20000
RTPENGINE_PORT_MIN=10000
RTPENGINE_PUBLIC_IP=103.199.185.165

# InfluxDB Settings
# ----------------
INFLUXDB_INIT_ORG=fonoster
INFLUXDB_INIT_PASSWORD=InfluxDB@Secure2025!
INFLUXDB_INIT_TOKEN=ghjNQ59FW4oi3bAiMTtfMyVnqtbwq0Iib58D63Lgk3pcrEFFPT0d9tnRKzHk98HNqZJUPc_mpXVkk07_JhBhJg==
INFLUXDB_INIT_USERNAME=influxdb

# Database Security Configuration
# -----------------------------
# For production environments, we recommend using a managed database service
POSTGRES_PASSWORD=PostgreSQL@2025!
POSTGRES_USER=postgres
EOF

# Passo 7: Copiar o arquivo de configuração Envoy
cat > config/envoy.yaml << 'EOF'
# Envoy configuration without tls for development and testing.
# Do not use this configuration in production. Please check the docs for examples using tls.
static_resources:
  listeners:
    - name: listener_http
      address:
        socket_address: { address: 0.0.0.0, port_value: 8449 }
      filter_chains:
        - filters:
          - name: envoy.filters.network.http_connection_manager
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
              codec_type: auto
              stat_prefix: ingress_http
              route_config:
                name: local_route
                virtual_hosts:
                  - name: local_service
                    domains: ["*"]
                    routes:
                      - match: { prefix: "/api" }
                        route:
                          cluster: apiserver-cluster-http
                          timeout: 0s                    
                      - match: { prefix: "/" }
                        route:
                          cluster: apiserver-cluster
                          timeout: 0s
                          max_stream_duration:
                            grpc_timeout_header_max: 0s
                    cors:
                      allow_origin_string_match:
                        - prefix: "*"
                      allow_methods: GET, PUT, DELETE, POST, OPTIONS
                      allow_headers: token,accesskeyid,keep-alive,user-agent,cache-control,content-type,content-transfer-encoding,x-accept-content-transfer-encoding,x-accept-response-streaming,x-user-agent,x-grpc-web,grpc-timeout
                      max_age: "1728000"
                      expose_headers: grpc-status,grpc-message
              http_filters:
                - name: envoy.filters.http.grpc_web
                  typed_config:
                    "@type": type.googleapis.com/envoy.extensions.filters.http.grpc_web.v3.GrpcWeb
                - name: envoy.filters.http.cors
                  typed_config:
                    "@type": type.googleapis.com/envoy.extensions.filters.http.cors.v3.Cors
                - name: envoy.filters.http.router
                  typed_config:
                    "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router

  clusters:
    - name: apiserver-cluster
      type: logical_dns
      connect_timeout: 20s
      http2_protocol_options: {}
      lb_policy: round_robin
      load_assignment:
        cluster_name: apiserver-cluster
        endpoints:
          - lb_endpoints:
              - endpoint:
                  address:
                    socket_address:
                      address: apiserver
                      port_value: 50051
    - name: apiserver-cluster-http
      type: logical_dns
      connect_timeout: 20s
      lb_policy: round_robin
      load_assignment:
        cluster_name: apiserver-cluster-http
        endpoints:
          - lb_endpoints:
              - endpoint:
                  address:
                    socket_address:
                      address: apiserver
                      port_value: 9876
EOF

echo "Configuração completa. Execute os seguintes comandos na VPS:"
echo "chmod +x config_fonoster.sh"
echo "./config_fonoster.sh"
echo "docker-compose down -v"
echo "docker-compose up -d"
echo ""
echo "Após a instalação, acesse a interface em: http://103.199.185.165:8282"
echo "Use as credenciais:"
echo "Email: admin@fonoster.local"
echo "Senha: SuperSecureAdmin2025!" 