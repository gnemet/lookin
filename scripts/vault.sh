#!/bin/bash
# vault.sh — GPG symmetric encryption for sensitive env files.
# Shared master: claude-base/scripts/shared/vault.sh
# To sync to a project: cp ../claude-base/scripts/shared/vault.sh scripts/vault.sh
# Passphrase resolution: $VAULT_PASS env var -> ./.vault_pass -> ~/.vault_pass

ACTION=$1
FILE=$2

usage() {
    echo "Usage: $0 [lock|unlock|status|verify|diff|lock-all|unlock-all|status-all] [file]"
    echo "  $0 lock .env"
    echo "  $0 unlock butalam       # shortcut: resolves to opt/envs/.env_butalam"
    echo "  $0 lock-all             # locks all files in opt/envs/"
    echo "  $0 status-all           # shows status of all env files"
    echo ""
    echo "Passphrase: \$VAULT_PASS env var -> ./.vault_pass -> ~/.vault_pass"
    exit 1
}

check_vault_pass() {
    if [[ -z "$VAULT_PASS" ]]; then
        if [[ -f "./.vault_pass" ]]; then
            VAULT_PASS=$(cat "./.vault_pass")
        elif [[ -f "$HOME/.vault_pass" ]]; then
            VAULT_PASS=$(cat "$HOME/.vault_pass")
        fi
    fi
    if [[ -z "$VAULT_PASS" ]]; then
        echo "Error: VAULT_PASS not set and no .vault_pass file found."
        echo "Set it: export VAULT_PASS='your_password'"
        echo "OR: echo 'your_password' > ~/.vault_pass && chmod 600 ~/.vault_pass"
        exit 1
    fi
}

check_gpg() {
    if ! command -v gpg &> /dev/null; then
        echo "Error: gpg is not installed."
        exit 1
    fi
}

if [[ -z "$ACTION" ]]; then usage; fi

if [[ "$ACTION" == "lock-all" || "$ACTION" == "unlock-all" || "$ACTION" == "status-all" ]]; then
    FILE="__bulk__"
fi

if [[ -z "$FILE" ]]; then usage; fi

DEFAULT_VAULT_DIR="opt/envs"
TARGET_FILE="$FILE"

# Auto-resolve shortcuts (e.g., 'butalam' -> 'opt/envs/.env_butalam')
if [[ ! -f "$FILE" && ! -f "$FILE.gpg" && "$FILE" != "__bulk__" ]]; then
    if [[ -f "$DEFAULT_VAULT_DIR/.env_$FILE" || -f "$DEFAULT_VAULT_DIR/.env_$FILE.gpg" ]]; then
        FILE="$DEFAULT_VAULT_DIR/.env_$FILE"
        echo "Auto-resolved shortcut to: $FILE"
        TARGET_FILE="$FILE"
    fi
fi

lock() {
    check_gpg; check_vault_pass
    [[ ! -f "$FILE" ]] && { echo "Error: '$FILE' not found."; exit 1; }
    echo "Encrypting $FILE..."
    printf '%s' "$VAULT_PASS" | gpg --symmetric --cipher-algo AES256 --batch --yes \
        --passphrase-fd 0 --pinentry-mode loopback "$FILE"
    [[ -f "$FILE.gpg" ]] && echo "Created $FILE.gpg" || { echo "Encryption failed."; exit 1; }
}

unlock() {
    check_gpg; check_vault_pass
    [[ ! -f "$FILE.gpg" ]] && { echo "Error: '$FILE.gpg' not found."; exit 1; }
    echo "Decrypting $FILE.gpg..."
    TMP_FILE=$(mktemp)
    printf '%s' "$VAULT_PASS" | gpg --decrypt --batch --yes \
        --passphrase-fd 0 --pinentry-mode loopback "$FILE.gpg" > "$TMP_FILE"
    if [[ $? -eq 0 ]]; then
        mv "$TMP_FILE" "$TARGET_FILE"
        echo "Restored $TARGET_FILE"
    else
        rm -f "$TMP_FILE"
        echo "Decryption failed."
        exit 1
    fi
}

verify() {
    check_gpg; check_vault_pass
    [[ ! -f "$FILE" ]]     && { echo "Error: '$FILE' not found."; exit 1; }
    [[ ! -f "$FILE.gpg" ]] && { echo "Error: '$FILE.gpg' not found."; exit 1; }
    echo "Verifying $FILE against $FILE.gpg..."
    RAW_HASH=$(sha256sum "$FILE" | awk '{print $1}')
    GPG_HASH=$(printf '%s' "$VAULT_PASS" | gpg --decrypt --batch --yes \
        --passphrase-fd 0 --pinentry-mode loopback "$FILE.gpg" 2>/dev/null | sha256sum | awk '{print $1}')
    if [[ "$RAW_HASH" == "$GPG_HASH" ]]; then
        echo "Verification SUCCESS (SHA256: $RAW_HASH)"
    else
        echo "Verification FAILED: content mismatch."
        echo "Raw: $RAW_HASH"
        echo "GPG: $GPG_HASH"
        exit 1
    fi
}

diff_files() {
    check_gpg; check_vault_pass
    [[ ! -f "$FILE" ]]     && { echo "Error: '$FILE' not found."; exit 1; }
    [[ ! -f "$FILE.gpg" ]] && { echo "Error: '$FILE.gpg' not found."; exit 1; }
    echo "Diffing $FILE against $FILE.gpg..."
    TMP_FILE=$(mktemp)
    printf '%s' "$VAULT_PASS" | gpg --decrypt --batch --yes \
        --passphrase-fd 0 --pinentry-mode loopback "$FILE.gpg" > "$TMP_FILE" 2>/dev/null
    if [[ $? -eq 0 ]]; then
        diff --color=always -u "$TMP_FILE" "$FILE"
        DIFF_RESULT=$?
        rm -f "$TMP_FILE"
        [[ $DIFF_RESULT -eq 0 ]] && echo "No differences found."
    else
        rm -f "$TMP_FILE"
        echo "Decryption failed."
        exit 1
    fi
}

status() {
    if [[ -f "$FILE" && -f "$FILE.gpg" ]]; then
        echo "Status '$FILE': both raw and encrypted exist."
        [[ "$FILE" -nt "$FILE.gpg" ]] && echo "Warning: raw is newer — run '$0 lock $FILE'" || echo "Up to date."
    elif [[ -f "$FILE.gpg" ]]; then
        echo "Status '$FILE': encrypted only — run '$0 unlock $FILE' to restore."
    elif [[ -f "$FILE" ]]; then
        echo "Status '$FILE': raw only — run '$0 lock $FILE' to protect."
    else
        echo "Status '$FILE': no files found."
    fi
}

lock_all() {
    check_gpg; check_vault_pass
    echo "Locking all env files in $DEFAULT_VAULT_DIR/..."
    for f in "$DEFAULT_VAULT_DIR"/.env_*; do
        [[ "$f" == *.gpg ]] && continue
        FILE="$f"; lock
    done
    echo "All env files locked."
}

unlock_all() {
    check_gpg; check_vault_pass
    echo "Unlocking all env files in $DEFAULT_VAULT_DIR/..."
    for f in "$DEFAULT_VAULT_DIR"/.env_*.gpg; do
        [[ ! -f "$f" ]] && continue
        FILE="${f%.gpg}"; TARGET_FILE="$FILE"; unlock
    done
    echo "All env files unlocked."
}

status_all() {
    echo "Vault status for $DEFAULT_VAULT_DIR/:"
    for f in "$DEFAULT_VAULT_DIR"/.env_*; do
        [[ "$f" == *.gpg ]] && continue
        base=$(basename "$f")
        if [[ -f "$f.gpg" ]]; then
            [[ "$f" -nt "$f.gpg" ]] && echo "  STALE  $base (raw newer — needs lock)" || echo "  OK     $base"
        else
            echo "  PLAIN  $base (not encrypted)"
        fi
    done
    for f in "$DEFAULT_VAULT_DIR"/.env_*.gpg; do
        [[ ! -f "$f" ]] && continue
        raw="${f%.gpg}"
        [[ ! -f "$raw" ]] && echo "  LOCKED $(basename "$raw") (encrypted only — needs unlock)"
    done
}

case "$ACTION" in
    lock)       lock       ;;
    unlock)     unlock     ;;
    lock-all)   lock_all   ;;
    unlock-all) unlock_all ;;
    verify)     verify     ;;
    diff)       diff_files ;;
    status)     status     ;;
    status-all) status_all ;;
    *)          usage      ;;
esac
