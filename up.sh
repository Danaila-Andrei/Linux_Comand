#!/bin/bash

LOCK_FILE="/var/lock/my_script.lock"

# Funcție pentru a înregistra mesaje în jurnalul sistemului
log() {
    logger "up.sh: $1"
}

# Verifică dacă un alt proces rulează deja
if [ -e "$LOCK_FILE" ]; then
    log "O altă instanță a scriptului rulează deja. Se încheie."
    exit 1
fi

# Creează fișierul de blocare
touch "$LOCK_FILE"

# La sfârșitul execuției, șterge fișierul de blocare
cleanup() {
    rm -f "$LOCK_FILE"
}

trap cleanup EXIT


# Înregistrează începutul scriptului
log "Scriptul a început"

# Funcție pentru a verifica conectivitatea la rețea
check_connectivity() {
    if ping -c 1 google.com >/dev/null; then
        return 0
    else
        return 1
    fi
}

# Funcție pentru a actualiza un repository mirror
update_mirror() {
    local repo_name=$1
    local repo_url=$2

    if [ ! -d "$repo_name" ]; then
        log "Se clonează $repo_name"
        git clone "$repo_url" "$repo_name"
    else
        log "Se actualizează $repo_name"
        cd "$repo_name" || return
        git pull
        cd ..
    fi
}

# Funcție pentru a gestiona pierderea conectivității la rețea
handle_connectivity_loss() {
    local checks=0
    while [ "$checks" -lt 3 ]; do
        if check_connectivity; then
            return 0
        fi
        ((checks++))
        sleep 5
    done
    log "Nu există conectivitate la rețea timp de 15 secunde. Se anulează actualizarea."
    exit 1
}

# Funcție principală
main() {
    # Verifică conectivitatea la rețea
    if ! check_connectivity; then
        handle_connectivity_loss
    fi

    # Actualizează mirror-urile
    update_mirror "linux" "https://github.com/torvalds/linux"
    update_mirror "glibc" "https://github.com/bminor/glibc"

    # Înregistrează sfârșitul scriptului
    log "Scriptul a sfârșit"

}

# Trap Ctrl+C și semnalul de ieșire pentru a înregistra  iesirea 
trap 'log "Scriptul a ieșit"; exit' INT TERM

# Execută funcția principală
main
