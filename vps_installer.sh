#!/bin/bash

# Colores para el menú
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Sin color

# Encabezado del menú con información del servidor
display_header() {
  clear
  echo -e "${RED}==============================================${NC}"
  echo -e "${GREEN}     Welcome To Script Premium Franata Store  ${NC}"
  echo -e "${RED}==============================================${NC}"
  echo -e "  System OS  = $(lsb_release -d | cut -f2)"
  echo -e "  Server RAM = $(free -m | awk 'NR==2 {print $2}') MB"
  echo -e "  Uptime     = $(uptime -p)"
  echo -e "  Date       = $(date '+%d/%m/%Y')"
  echo -e "  Time       = $(date '+%H:%M:%S')"
  echo -e "  IP VPS     = $(hostname -I | awk '{print $1}')"
  echo -e "  Domain     = premium.vpshuman.xyz"
  echo -e "${RED}==============================================${NC}"
}

# Mostrar estado de los servicios
show_services_status() {
  echo -e "\n${CYAN}>> STATUS SERVER <<${NC}"
  echo -e " SSH      : $(systemctl is-active ssh | grep -q 'active' && echo ON || echo OFF)"
  echo -e " NGINX    : $(systemctl is-active nginx | grep -q 'active' && echo ON || echo OFF)"
  echo -e " Xray     : $(systemctl is-active xray | grep -q 'active' && echo ON || echo OFF)"
  echo -e " Dropbear : $(systemctl is-active dropbear | grep -q 'active' && echo ON || echo OFF)"
  echo -e " WS-ePRO  : ON"
  echo -e "=============================================="
}

# Automatizar certificados SSL con Let's Encrypt para subdominio
function setup_ssl_certificate() {
    echo -n "Ingrese el subdominio para el certificado SSL: "
    read domain

    echo -e "${GREEN}Instalando y configurando Let's Encrypt...${NC}"
    check_command certbot certonly --standalone -d "$domain" --agree-tos -m admin@$domain --non-interactive
    echo -e "${GREEN}Certificado SSL generado correctamente para $domain.${NC}"
}

# Menú principal
function main_menu() {
    while true; do
        display_header
        show_services_status
        echo -e "\n${CYAN}>> MENÚ PRINCIPAL <<${NC}"
        echo -e "${BLUE}[1] Instalar dependencias${NC}"
        echo -e "${BLUE}[2] Configurar puertos SSL y SSH${NC}"
        echo -e "${BLUE}[3] Configurar certificado SSL (Let's Encrypt para subdominio)${NC}"
        echo -e "${BLUE}[4] Realizar respaldo de configuraciones${NC}"
        echo -e "${BLUE}[5] Restaurar configuraciones${NC}"
        echo -e "${BLUE}[6] Crear usuario${NC}"
        echo -e "${BLUE}[7] Editar usuario${NC}"
        echo -e "${BLUE}[8] Salir${NC}"
        echo -n "Seleccione una opción: "
        read opt

        case $opt in
            1) install_dependencies ;;
            2) configure_ports ;;
            3) setup_ssl_certificate ;;
            4) backup_configs ;;
            5) restore_configs ;;
            6) create_user ;;
            7) edit_user ;;
            8) exit 0 ;;
            *) echo -e "${RED}Opción no válida.${NC}" ;;
        esac

        read -p "Presione Enter para continuar..."
    done
}

# Funciones auxiliares y dependencias existentes
function check_command() {
    "$@" || { echo -e "${RED}Error al ejecutar: $*${NC}"; exit 1; }
}

function install_dependencies() {
    echo -e "${GREEN}Instalando dependencias...${NC}"
    check_command apt update
    check_command apt install -y curl wget unzip jq net-tools nginx python3 python3-pip certbot
    check_command bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)
    echo -e "${GREEN}Dependencias instaladas correctamente.${NC}"
}

function configure_ports() {
    echo -e "${GREEN}Configurando puertos...${NC}"
    for port in 22 80 90 443 444 442; do
        iptables -A INPUT -p tcp --dport $port -j ACCEPT
        iptables -A INPUT -p udp --dport $port -j ACCEPT
    done
    iptables-save > /etc/iptables/rules.v4
    echo -e "${GREEN}Configuración de puertos completada.${NC}"
}

function backup_configs() {
    echo -e "${GREEN}Realizando respaldo de configuraciones...${NC}"
    backup_file="/root/vps_backup_$(date +%Y%m%d%H%M%S).tar.gz"
    check_command tar -czf $backup_file /etc/v2ray /etc/iptables/rules.v4
    echo -e "${GREEN}Respaldo realizado en: $backup_file${NC}"
}

function restore_configs() {
    echo -n "Ingrese la ruta del archivo de respaldo: "
    read backup_file
    if [ ! -f "$backup_file" ]; then
        echo -e "${RED}Archivo de respaldo no encontrado.${NC}"
        return
    fi
    check_command tar -xzf $backup_file -C /
    echo -e "${GREEN}Configuraciones restauradas correctamente.${NC}"
}

function create_user() {
    echo -n "Ingrese el nombre del usuario: "
    read username
    echo -n "Ingrese la fecha de vencimiento (YYYY-MM-DD): "
    read exp_date

    if validate_date $exp_date; then
        useradd -e $exp_date -m $username
        echo -e "${GREEN}Usuario $username creado con éxito.${NC}"
    else
        echo -e "${RED}No se pudo crear el usuario debido a un error en la fecha.${NC}"
    fi
}

function edit_user() {
    echo -n "Ingrese el nombre del usuario a editar: "
    read username
    echo -n "Ingrese la nueva fecha de vencimiento (YYYY-MM-DD): "
    read new_exp_date

    if validate_date $new_exp_date; then
        chage -E $(date -d $new_exp_date +%s) $username
        echo -e "${GREEN}Usuario $username actualizado con éxito.${NC}"
    else
        echo -e "${RED}No se pudo actualizar el usuario debido a un error en la fecha.${NC}"
    fi
}

function validate_date() {
    date -d "$1" +%Y-%m-%d &> /dev/null
    if [ $? -ne 0 ]; then
        echo -e "${RED}Formato de fecha no válido. Debe ser YYYY-MM-DD.${NC}"
        return 1
    fi
    return 0
}

# Ejecutar el menú principal
main_menu
