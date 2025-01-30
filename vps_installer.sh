#!/bin/bash

# Colores para el menú
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Sin color

# Función para instalar dependencias necesarias
function install_dependencies() {
    echo -e "${GREEN}Instalando dependencias...${NC}"
    apt update
    apt install -y curl wget unzip jq net-tools nginx python3 python3-pip
    bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)
    echo -e "${GREEN}Dependencias instaladas correctamente.${NC}"
}

# Configuración de puertos
function configure_ports() {
    echo -e "${GREEN}Configurando puertos...${NC}"
    # Abrir puertos con iptables
    for port in 22 80 90 443 444 442; do
        iptables -A INPUT -p tcp --dport $port -j ACCEPT
        iptables -A INPUT -p udp --dport $port -j ACCEPT
    done
    echo -e "${GREEN}Puertos abiertos: 22, 80, 90, 443, 444, 442${NC}"

    # Guardar reglas de iptables
    iptables-save > /etc/iptables/rules.v4
    echo -e "${GREEN}Configuración de puertos completada.${NC}"
}

# Función para configurar conexiones V2Ray
function configure_v2ray() {
    echo -e "${GREEN}Configurando V2Ray...${NC}"
    mkdir -p /etc/v2ray
    cat <<EOF > /etc/v2ray/config.json
{
    "log": {
        "loglevel": "info"
    },
    "inbounds": [
        {
            "port": 443,
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "$(uuidgen)",
                        "alterId": 64
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/v2ray"
                }
            }
        },
        {
            "port": 80,
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "$(uuidgen)",
                        "alterId": 64
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/v2ray"
                }
            }
        },
        {
            "port": 442,
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "$(uuidgen)",
                        "alterId": 64
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/v2ray"
                }
            }
        },
        {
            "port": 90,
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "$(uuidgen)",
                        "alterId": 64
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/v2ray"
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "settings": {}
        }
    ]
}
EOF
    systemctl restart v2ray
    echo -e "${GREEN}V2Ray configurado y reiniciado.${NC}"
}

# Mostrar información del servidor
function show_server_info() {
    clear
    echo -e "${CYAN}INFO SERVER${NC}"
    echo -e "System Uptime : $(uptime -p)"
    echo -e "Memory Usage  : $(free -h | awk '/Mem:/ {print $3 "/" $2}')"
    echo -e "VPN Core     : XRAY-CORE"
    echo -e "Domain       : $(hostname -f)"
    echo -e "IP VPS       : $(curl -s ifconfig.me)"
    echo -e "[ XRAY-CORE : ON ]"
    echo -e "[ NGINX     : ON ]"
    echo -e "Traffic     : Today | Yesterday | Month"
    echo -e "Download    : 0.00G | 0.00G     | 0.00G"
    echo -e "Upload      : 0.00G | 0.00G     | 0.00G"
    echo -e "Total       : 0.00G | 0.00G     | 0.00G"
}

# Menú de autoscripts
function autoscript_menu() {
    echo -e "${CYAN}AUTOSCRIPT MENU${NC}"
    echo -e "${BLUE}[1] XRAY Vmess Websocket Panel${NC}"
    echo -e "${BLUE}[2] XRAY Vless Websocket Panel${NC}"
    echo -e "${BLUE}[3] XRAY Trojan Websocket Panel${NC}"
    echo -e "${BLUE}[4] SSH Websocket Panel${NC}"
}

# Menú de sistema
function system_menu() {
    echo -e "${CYAN}SYSTEM MENU${NC}"
    echo -e "${BLUE}[5] Change Domain${NC}"
    echo -e "${BLUE}[6] Renew Certificate XRAY${NC}"
    echo -e "${BLUE}[7] Check VPN Status${NC}"
    echo -e "${BLUE}[8] Check VPN Port${NC}"
    echo -e "${BLUE}[9] Restart VPN Services${NC}"
    echo -e "${BLUE}[10] Speedtest VPS${NC}"
    echo -e "${BLUE}[11] Check RAM${NC}"
    echo -e "${BLUE}[12] Check Bandwidth${NC}"
    echo -e "${BLUE}[13] DNS Changer${NC}"
    echo -e "${BLUE}[14] Netflix Checker${NC}"
    echo -e "${BLUE}[15] Backup${NC}"
    echo -e "${BLUE}[16] Restore${NC}"
    echo -e "${BLUE}[17] Reboot${NC}"
}

# Función para gestionar usuarios
function user_management_menu() {
    while true; do
        clear
        echo -e "${CYAN}GESTIÓN DE USUARIOS${NC}"
        echo -e "${BLUE}[1] Crear usuario${NC}"
        echo -e "${BLUE}[2] Editar usuario${NC}"
        echo -e "${BLUE}[3] Eliminar usuario${NC}"
        echo -e "${BLUE}[4] Listar usuarios${NC}"
        echo -e "${BLUE}[5] Volver al menú principal${NC}"
        echo -n "Seleccione una opción: "
        read opt

        case $opt in
            1) create_user ;;
            2) edit_user ;;
            3) delete_user ;;
            4) list_users ;;
            5) break ;;
            *) echo -e "${RED}Opción no válida.${NC}" ;;
        esac

        read -p "Presione Enter para continuar..."
    done
}

# Crear usuario
function create_user() {
    echo -n "Ingrese el nombre del usuario: "
    read username
    echo -n "Ingrese la fecha de vencimiento (YYYY-MM-DD): "
    read exp_date
    useradd -e $exp_date -m $username
    echo -e "${GREEN}Usuario $username creado con éxito.${NC}"
}

# Editar usuario
function edit_user() {
    echo -n "Ingrese el nombre del usuario a editar: "
    read username
    echo -n "Ingrese la nueva fecha de vencimiento (YYYY-MM-DD): "
    read new_exp_date
    chage -E $(date -d $new_exp_date +%s) $username
    echo -e "${GREEN}Usuario $username actualizado con éxito.${NC}"
}

# Eliminar usuario
function delete_user() {
    echo -n "Ingrese el nombre del usuario a eliminar: "
    read username
    userdel -r $username
    echo -e "${GREEN}Usuario $username eliminado con éxito.${NC}"
}

# Listar usuarios
function list_users() {
    echo -e "${CYAN}Usuarios en el sistema:${NC}"
    cut -d: -f1 /etc/passwd
}

# Menú principal
function main_menu() {
    while true; do
        clear
        show_server_info
        echo -e "${CYAN}VPS MULTIPUERTO ADMINISTRADOR${NC}"
        echo -e "${BLUE}[1] Instalar dependencias${NC}"
        echo -e "${BLUE}[2] Configurar puertos SSL y SSH${NC}"
        echo -e "${BLUE}[3] Configurar V2Ray (443, 80, 442, 90)${NC}"
        echo -e "${BLUE}[4] Gestión de usuarios${NC}"
        echo -e "${BLUE}[5] Menú Autoscripts${NC}"
        echo -e "${BLUE}[6] Menú Sistema${NC}"
        echo -e "${BLUE}[7] Salir${NC}"
        echo -n "Seleccione una opción: "
        read opt

        case $opt in
            1) install_dependencies ;;
            2) configure_ports ;;
            3) configure_v2ray ;;
            4) user_management_menu ;;
            5) autoscript_menu ;;
            6) system_menu ;;
            7) exit 0 ;;
            *) echo -e "${RED}Opción no válida.${NC}" ;;
        esac

        read -p "Presione Enter para continuar..."
    done
}

# Ejecutar el menú principal
main_menu
