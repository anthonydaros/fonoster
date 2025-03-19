# Fonoster - Ambiente de Desenvolvimento

Este repositório contém a configuração do Docker Compose para o Fonoster, uma plataforma open-source para comunicações programáveis.

## Pré-requisitos

- Docker
- Docker Compose
- 4GB de RAM mínimo
- 10GB de espaço em disco

## Configuração Inicial

1. Clone este repositório:
   ```
   git clone https://github.com/seu-usuario/fonoster.git
   cd fonoster
   ```

2. O arquivo `.env` já está configurado com os valores padrão. Você pode modificá-lo de acordo com suas necessidades antes de iniciar os contêineres.

3. Crie o diretório para configurações:
   ```
   mkdir -p config
   ```

## Inicialização

Para iniciar todos os serviços:

```
docker-compose up -d
```

A primeira inicialização pode levar alguns minutos, pois os contêineres serão baixados e as configurações iniciais serão geradas.

## Acesso ao Sistema

- **WebUI**: http://localhost:8282
  - Usuário: admin@fonoster.com
  - Senha: adminadmin

- **Adminer** (gerenciamento do banco de dados): http://localhost:8283
  - Sistema: PostgreSQL
  - Servidor: postgres
  - Usuário: postgres
  - Senha: fonoster
  - Base de dados: fonoster

## Serviços e Portas

- **API Server**: 50051 (gRPC)
- **Routr**: 5060 (SIP)
- **WebUI**: 8282 (HTTP)
- **Adminer**: 8283 (HTTP)
- **Envoy Proxy**: 8449 (HTTP/gRPC-Web)
- **InfluxDB**: 8086 (HTTP)

## Solução de Problemas

Se encontrar problemas na inicialização:

1. Verifique os logs dos contêineres:
   ```
   docker-compose logs -f [nome-do-serviço]
   ```

2. Verifique se todas as portas necessárias estão disponíveis em seu sistema.

3. Para reiniciar um serviço específico:
   ```
   docker-compose restart [nome-do-serviço]
   ```

## Parando o Ambiente

Para parar todos os serviços:

```
docker-compose down
```

Para parar e remover todos os dados (volumes):

```
docker-compose down -v
```

## Notas

- Esta configuração é destinada apenas para desenvolvimento e testes.
- Não use em produção sem ajustes adicionais de segurança.
