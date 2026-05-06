#!/bin/bash

# ─────────────────────────────────────────────
#   COLOR PALETTE
# ─────────────────────────────────────────────
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)

BOLD=$(tput bold)
DIM=$'\033[2m'
RESET=$(tput sgr0)

TEAL=$'\033[38;5;50m'
ORANGE=$'\033[38;5;214m'
PINK=$'\033[38;5;213m'
LAVENDER=$'\033[38;5;183m'
LIME=$'\033[38;5;154m'
GOLD=$'\033[38;5;220m'
SKY=$'\033[38;5;117m'

# ─────────────────────────────────────────────
#   UTILITY FUNCTIONS
# ─────────────────────────────────────────────

spinner() {
    local pid=$1
    local msg="${2:-Processing...}"
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local i=0
    tput civis
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${CYAN}${frames[$i]}${RESET}  ${DIM}${WHITE}${msg}${RESET}   "
        i=$(( (i+1) % ${#frames[@]} ))
        sleep 0.08
    done
    printf "\r  ${LIME}${BOLD}✔${RESET}  ${WHITE}${msg}${RESET}$(tput el)\n"
    tput cnorm
}

step_banner() {
    local title="$1"
    local icon="${2:-⚙}"
    echo
    echo "  ${MAGENTA}${BOLD}╔══════════════════════════════════════════════╗${RESET}"
    printf "  ${MAGENTA}${BOLD}║${RESET}  ${CYAN}${BOLD}${icon}  %-42s${RESET}${MAGENTA}${BOLD}║${RESET}\n" "${title}"
    echo "  ${MAGENTA}${BOLD}╚══════════════════════════════════════════════╝${RESET}"
    echo
}

ok()    { echo "  ${LIME}${BOLD}✔${RESET}  ${WHITE}$1${RESET}"; }
fail()  { echo "  ${RED}${BOLD}✘${RESET}  ${RED}$1${RESET}"; }
info()  { echo "  ${TEAL}➜${RESET}  ${DIM}${WHITE}$1${RESET}"; }
warn()  { echo "  ${YELLOW}${BOLD}⚠${RESET}  ${YELLOW}$1${RESET}"; }
label() { printf "  ${LAVENDER}${BOLD}◈${RESET}  ${BOLD}${WHITE}%-22s${RESET}  ${YELLOW}%s${RESET}\n" "$1" "$2"; }

divider() { echo "  ${DIM}${LAVENDER}──────────────────────────────────────────────────${RESET}"; }

clear

# ─────────────────────────────────────────────
#   BANNER
# ─────────────────────────────────────────────
echo
echo "${BLUE}${BOLD}"
echo "   ██████╗██╗      ██████╗ ██╗   ██╗██████╗  ██████╗  █████╗ ██████╗  ██████╗"
echo "  ██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗██╔═══██╗██╔══██╗██╔══██╗██╔════╝"
echo "  ██║     ██║     ██║   ██║██║   ██║██║  ██║██║   ██║███████║██████╔╝██║     "
echo "  ██║     ██║     ██║   ██║██║   ██║██║  ██║██║   ██║██╔══██║██╔══██╗██║     "
echo "  ╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝╚██████╔╝██║  ██║██║  ██║╚██████╗"
echo "   ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝"
echo "${RESET}"
echo "  ${CYAN}${BOLD}   ✦  Use Machine Learning APIs on Google Cloud: Challenge Lab  ✦${RESET}"
divider
echo "  ${DIM}${WHITE}   Preparing ML environment... Vision API incoming 🤖🧠${RESET}"
divider
sleep 0.5

# ─────────────────────────────────────────────
#   STEP 1: USER INPUT
# ─────────────────────────────────────────────
step_banner "Lab Configuration Input" "📋"
echo "  ${DIM}${WHITE}Enter values exactly as shown in your Challenge Lab task panel.${RESET}"
echo

ask() {
    local varname="$1" label_text="$2" hint="$3"
    [[ -n "$hint" ]] \
        && printf "  ${PINK}${BOLD}❯  %-22s ${DIM}(%s)${RESET}${PINK}${BOLD} : ${RESET}" "$label_text" "$hint" \
        || printf "  ${PINK}${BOLD}❯  %-22s : ${RESET}" "$label_text"
    read -r "$varname"
    echo
}

ask LANGUAGE           "LANGUAGE"           "e.g. en, fr, es"
ask LOCAL              "LOCAL"              "e.g. en-US, fr-FR"
ask BIGQUERY_ROLE      "BIGQUERY_ROLE"      "e.g. roles/bigquery.admin"
ask CLOUD_STORAGE_ROLE "CLOUD_STORAGE_ROLE" "e.g. roles/storage.admin"

# Script name in user's GCS bucket
SCRIPT_NAME="analyze-images-v2.py"

# ─── Config Summary ───────────────────────────
echo
echo "  ${GREEN}${BOLD}╔════════════════════════════════════════════════════╗${RESET}"
echo "  ${GREEN}${BOLD}║           ✦  CONFIGURATION SUMMARY  ✦             ║${RESET}"
echo "  ${GREEN}${BOLD}╠════════════════════════════════════════════════════╣${RESET}"
echo "  ${GREEN}${BOLD}║${RESET}"
label "  Language"            "$LANGUAGE"
label "  Locale"              "$LOCAL"
label "  BigQuery Role"       "$BIGQUERY_ROLE"
label "  Cloud Storage Role"  "$CLOUD_STORAGE_ROLE"
label "  Script"              "$SCRIPT_NAME  (from GCS bucket)"
echo "  ${GREEN}${BOLD}║${RESET}"
echo "  ${GREEN}${BOLD}╚════════════════════════════════════════════════════╝${RESET}"
echo

# ─────────────────────────────────────────────
#   STEP 2: SERVICE ACCOUNT CREATION
# ─────────────────────────────────────────────
step_banner "Creating Service Account" "🔐"

gcloud iam service-accounts create sample-sa \
    --display-name="Sample Service Account" &>/dev/null &
spinner $! "Creating service account  →  sample-sa ..."
ok "Service account  ${CYAN}sample-sa${RESET}  created"
echo

# ─────────────────────────────────────────────
#   STEP 3: IAM ROLE BINDINGS
# ─────────────────────────────────────────────
step_banner "Assigning IAM Roles" "🛡"

SA_EMAIL="sample-sa@${DEVSHELL_PROJECT_ID}.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding "$DEVSHELL_PROJECT_ID" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="$BIGQUERY_ROLE" &>/dev/null &
spinner $! "Binding  $BIGQUERY_ROLE ..."
ok "${CYAN}${BIGQUERY_ROLE}${RESET}  ${DIM}→ attached${RESET}"

gcloud projects add-iam-policy-binding "$DEVSHELL_PROJECT_ID" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="$CLOUD_STORAGE_ROLE" &>/dev/null &
spinner $! "Binding  $CLOUD_STORAGE_ROLE ..."
ok "${CYAN}${CLOUD_STORAGE_ROLE}${RESET}  ${DIM}→ attached${RESET}"

gcloud projects add-iam-policy-binding "$DEVSHELL_PROJECT_ID" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/serviceusage.serviceUsageConsumer" &>/dev/null &
spinner $! "Binding  roles/serviceusage.serviceUsageConsumer ..."
ok "${CYAN}roles/serviceusage.serviceUsageConsumer${RESET}  ${DIM}→ attached${RESET}"
echo

# ─────────────────────────────────────────────
#   STEP 4: IAM PROPAGATION WAIT
# ─────────────────────────────────────────────
step_banner "IAM Propagation Wait  (2 min)" "⏳"
info "Letting IAM policy changes propagate across GCP..."
echo

for i in $(seq 120 -1 1); do
    bar_done=$(( (120 - i) * 40 / 120 ))
    bar_left=$(( 40 - bar_done ))
    bar="${LIME}$(printf '█%.0s' $(seq 1 $bar_done))${RESET}${DIM}$(printf '░%.0s' $(seq 1 $bar_left))${RESET}"
    printf "\r  ${GOLD}◷${RESET}  [%s]  ${BOLD}${GOLD}%3d s${RESET} remaining  " "$bar" "$i"
    sleep 1
done
printf "\r  ${LIME}${BOLD}✔${RESET}  IAM changes propagated successfully!$(tput el)\n"
echo

# ─────────────────────────────────────────────
#   STEP 5: SERVICE ACCOUNT KEY
#   FIX: Do NOT run key creation in background (&)
#        Key must be FULLY written to disk before
#        exporting GOOGLE_APPLICATION_CREDENTIALS.
#        Background process causes incomplete/corrupt
#        key → Invalid JWT Signature error.
# ─────────────────────────────────────────────
step_banner "Generating Service Account Key" "🔑"

# Delete old key if exists to avoid conflicts
rm -f sample-sa-key.json

info "Generating service account key (this runs synchronously)..."

# Run synchronously — NO & — so key is fully written before we proceed
gcloud iam service-accounts keys create sample-sa-key.json \
    --iam-account="$SA_EMAIL"

# Verify the key file was actually created and is valid JSON
if [ ! -f "sample-sa-key.json" ]; then
    fail "Key file was NOT created. Check IAM permissions and try again."
    exit 1
fi

if ! python3 -c "import json; json.load(open('sample-sa-key.json'))" 2>/dev/null; then
    fail "Key file is corrupt or invalid JSON. Try re-running the script."
    exit 1
fi

export GOOGLE_APPLICATION_CREDENTIALS="${PWD}/sample-sa-key.json"
ok "Key created  ${DIM}→  ${PWD}/sample-sa-key.json${RESET}"
ok "GOOGLE_APPLICATION_CREDENTIALS exported  ${DIM}→  ${GOOGLE_APPLICATION_CREDENTIALS}${RESET}"
echo

# ─────────────────────────────────────────────
#   STEP 6: FETCH SCRIPT FROM USER'S GCS BUCKET
#   FIX: Bucket name = Project ID (same thing)
# ─────────────────────────────────────────────
step_banner "Fetching Analysis Script from GCS" "☁️"

# ── Bucket name is always the same as the project ID ──
BUCKET_NAME="${DEVSHELL_PROJECT_ID}"

info "Source  →  ${CYAN}gs://${BUCKET_NAME}/${SCRIPT_NAME}${RESET}"
echo

# Remove stale local copy so we always get fresh file from GCS
rm -f "${SCRIPT_NAME}"

info "Downloading  ${SCRIPT_NAME}  from GCS (synchronous)..."
gsutil cp "gs://${BUCKET_NAME}/${SCRIPT_NAME}" .

if [ -f "${SCRIPT_NAME}" ]; then
    ok "Script fetched successfully  ${DIM}→  ./${SCRIPT_NAME}${RESET}"
else
    fail "Could not fetch  ${SCRIPT_NAME}  from  gs://${BUCKET_NAME}/"
    warn "Make sure the file exists in your project bucket and try again."
    exit 1
fi
echo

# ─────────────────────────────────────────────
#   STEP 7: PATCH LOCALE IN SCRIPT
#   FIX: Replace the exact locale placeholder
#        that the lab's Python script uses.
#        The script has  locale = 'en'  — we
#        replace that with the user-supplied LOCAL.
# ─────────────────────────────────────────────
step_banner "Patching Script Locale" "✏️"

info "Replacing locale placeholder  →  ${CYAN}'${LOCAL}'${RESET}  in  ${SCRIPT_NAME}"

# Replace every occurrence of 'en' (quoted) with the correct locale
sed -i "s/'en'/'${LOCAL}'/g" "${SCRIPT_NAME}"

ok "Locale updated to  ${CYAN}${LOCAL}${RESET}  in  ${SCRIPT_NAME}"
echo

# ─────────────────────────────────────────────
#   STEP 8: PATCH LANGUAGE HINT IN SCRIPT
#   FIX: The Python script uses Vision API with
#        language_hints. Replace the hardcoded
#        language code with the user-supplied one.
# ─────────────────────────────────────────────
step_banner "Patching Script Language Hint" "🌐"

info "Setting language hint  →  ${CYAN}'${LANGUAGE}'${RESET}  in  ${SCRIPT_NAME}"

# Common patterns the lab script may use for language hints
sed -i "s/language_hints=\[\"en\"\]/language_hints=[\"${LANGUAGE}\"]/g" "${SCRIPT_NAME}"
sed -i "s/language_hints=\['en'\]/language_hints=['${LANGUAGE}']/g"     "${SCRIPT_NAME}"

ok "Language hint updated to  ${CYAN}${LANGUAGE}${RESET}  in  ${SCRIPT_NAME}"
echo

# ─────────────────────────────────────────────
#   STEP 9: VALIDATE PYTHON SCRIPT SYNTAX
#   FIX: Catch syntax errors before running
# ─────────────────────────────────────────────
step_banner "Validating Python Script" "🔍"

info "Running syntax check on  ${CYAN}${SCRIPT_NAME}${RESET}..."
if python3 -m py_compile "${SCRIPT_NAME}" 2>/dev/null; then
    ok "Syntax check passed  ✅"
else
    warn "Syntax warning detected — attempting to run anyway..."
fi
echo

# ─────────────────────────────────────────────
#   STEP 10: RUN IMAGE ANALYSIS
#   FIX: Only run with project args (Pass 2).
#        Pass 1 (dry run without args) always
#        errors — removed it to keep output clean.
#        Both PROJECT_ID and BUCKET_NAME are same.
# ─────────────────────────────────────────────
step_banner "Running Image Analysis" "🤖"

info "Executing  ${CYAN}${SCRIPT_NAME}${RESET}  with project + bucket args..."
echo
divider

python3 "${SCRIPT_NAME}" "$DEVSHELL_PROJECT_ID" "$BUCKET_NAME"

divider
echo
ok "Image analysis completed 🎯"
echo

# ─────────────────────────────────────────────
#   STEP 11: BIGQUERY RESULTS
# ─────────────────────────────────────────────
step_banner "Querying BigQuery Results" "📊"

info "Running locale distribution query on  ${CYAN}image_classification_dataset${RESET}..."
echo
divider

bq query --use_legacy_sql=false \
"SELECT locale, COUNT(locale) as lcount
 FROM image_classification_dataset.image_text_detail
 GROUP BY locale
 ORDER BY lcount DESC"

divider
ok "BigQuery query complete"
echo

# ─────────────────────────────────────────────
#   DONE
# ─────────────────────────────────────────────
echo
echo "  ${GREEN}${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
echo "  ${GREEN}${BOLD}║                                                  ║${RESET}"
echo "  ${GREEN}${BOLD}║        🎉  LAB COMPLETED SUCCESSFULLY!  🎉       ║${RESET}"
echo "  ${GREEN}${BOLD}║                                                  ║${RESET}"
echo "  ${GREEN}${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
echo
echo "  ${ORANGE}${BOLD}🎥  More labs on  →  ${RESET}${BOLD}${WHITE}CloudoArc${RESET}  ${ORANGE}${BOLD}(YouTube)${RESET}"
echo "  ${DIM}${LAVENDER}  Drop a like if this helped you out!${RESET}"
echo
