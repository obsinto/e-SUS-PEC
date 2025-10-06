#!/bin/sh

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
ARGS=""

# Verificando variáveis de ambiente (usando DB_* ao invés de POSTGRES_*)
if [ -n "$DB_HOST" ] && [ -n "$DB_PORT" ] && [ -n "$POSTGRES_DB" ]; then
    DB_URL="jdbc:postgresql://$DB_HOST:$DB_PORT/$POSTGRES_DB"
fi

# Echo das variáveis de ambiente
echo -e "${GREEN}\n\n*******************"
echo "Variáveis de ambiente:"
echo "*******************"
echo "HTTPS_DOMAIN: ${HTTPS_DOMAIN}"
echo "DB_URL: ${DB_URL}"
echo "DB_USER: ${DB_USER}"  
echo "DB_PASSWORD: ${DB_PASSWORD}"
echo "JAR_FILENAME: ${JAR_FILENAME}"
echo "TRAINING: ${TRAINING}"
echo "*******************\n\n${NC}"

# NÃO GERAR CERTIFICADO - Traefik cuida disso
# if [ -n "$HTTPS_DOMAIN" ]; then
#   ARGS="$ARGS -cert-domain=${HTTPS_DOMAIN}"
# fi

# Verificando variáveis de banco de dados
if [ -n "$DB_URL" ]; then
  ARGS="$ARGS -url=${DB_URL}" 
fi

if [ -n "$DB_USER" ]; then
  ARGS="$ARGS -username=${DB_USER}"
fi

if [ -n "$DB_PASSWORD" ]; then  
  ARGS="$ARGS -password=${DB_PASSWORD}"
fi

# A ser executado java -jar
echo -e "${GREEN}\n\n*******************"
echo "java -jar ${JAR_FILENAME} -console ${ARGS} -continue"
echo "*******************\n\n${NC}"

# Executa o comando
java -jar ${JAR_FILENAME} -console ${ARGS} -continue

# Verificando se a variável de treinamento existe, caso sim, executa o SQL
if [ -n "$TRAINING" ]; then
  echo -e "${GREEN}Treinamento habilitado. Executando SQL de configuração...${NC}"
  
  # Exporta a senha do banco para evitar o prompt
  export PGPASSWORD="${DB_PASSWORD}"

  # Executa o comando SQL (usando DB_* ao invés de POSTGRES_*)
  psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${POSTGRES_DB} -c "update tb_config_sistema set ds_texto = null, ds_inteiro = 1 where co_config_sistema = 'TREINAMENTO';"
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Configuração de treinamento aplicada com sucesso.${NC}"
  else
    echo -e "${RED}Erro ao aplicar configuração de treinamento.${NC}"
  fi

  # Limpa a variável de senha para segurança
  unset PGPASSWORD
fi
