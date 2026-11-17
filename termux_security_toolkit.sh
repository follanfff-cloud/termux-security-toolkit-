#!/data/data/com.termux/files/usr/bin/bash
# =====================================================================
#  Termux Security Testing Toolkit Installer
#  สคริปต์ติดตั้งเครื่องมือทดสอบความปลอดภัยบน Termux (Android)
# =====================================================================
#  ⚠️  คำเตือนทางกฎหมาย / LEGAL DISCLAIMER  ⚠️
#  เครื่องมือเหล่านี้ใช้สำหรับ:
#    ✅ การเรียนรู้ด้านความมั่นคงปลอดภัยไซเบอร์ (CTF, TryHackMe, HackTheBox)
#    ✅ Bug Bounty Program (HackerOne, Bugcrowd ฯลฯ) ที่มีขอบเขตชัดเจน
#    ✅ Penetration Test บนระบบที่คุณเป็นเจ้าของหรือได้รับอนุญาตเป็นลายลักษณ์อักษร
#    ❌ ห้ามใช้เจาะระบบ/เว็บไซต์ของผู้อื่นโดยไม่ได้รับอนุญาต (ผิด พ.ร.บ. คอมพิวเตอร์ คดีอาญา)
#  ผู้ใช้ต้องรับผิดชอบต่อการใช้งานทุกอย่างด้วยตนเอง
# =====================================================================

set -e

# ---------- Color & UI ----------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'
BOLD='\033[1m'

info()  { echo -e "${CYAN}[*]${NC} $1"; }
ok()    { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
err()   { echo -e "${RED}[x]${NC} $1"; }

TOOLS_DIR="$HOME/security-tools"
mkdir -p "$TOOLS_DIR"

# ---------- Legal Acceptance ----------
clear
echo -e "${RED}${BOLD}============================================================${NC}"
echo -e "${RED}${BOLD}   ⚠️  TERMS OF USE / เงื่อนไขการใช้งาน  ⚠️${NC}"
echo -e "${RED}${BOLD}============================================================${NC}"
echo ""
echo -e "เครื่องมือในสคริปต์นี้เป็น Open Source Security Tools ที่ใช้"
echo -e "สำหรับ ${GREEN}การทดสอบความปลอดภัยที่ได้รับอนุญาต${NC} และ ${GREEN}การศึกษา${NC} เท่านั้น"
echo ""
echo -e "${RED}❌ ห้าม${NC} ใช้โจมตี สแกน หรือเจาะระบบ/เว็บไซต์ของผู้อื่นโดยไม่ได้รับ"
echo -e "   ความยินยอมเป็นลายลักษณ์อักษร (ผิด พ.ร.บ. คอมพิวเตอร์ พ.ศ. 2550)"
echo ""
echo -e "โดยการดำเนินการต่อ คุณยอมรับเงื่อนไขข้างต้นทั้งหมด"
echo ""
read -p "พิมพ์ [YES] เพื่อยอมรับและดำเนินการต่อ: " accept
if [ "$accept" != "YES" ]; then
    err "ยกเลิกการติดตั้ง"
    exit 1
fi

# ---------- Base Setup ----------
base_setup() {
    info "ติดตั้งพื้นฐานระบบ (อาจใช้เวลาสักครู่)..."
    pkg update -y && pkg upgrade -y
    pkg install -y python python2 git curl wget nano vim unzip tar \
        clang make cmake perl ruby nodejs golang openssh wget proot \
        termux-tools resolv-conf bind-utils
    pip install --upgrade pip
    ok "พื้นฐานระบบติดตั้งเสร็จสิ้น"
}

# ---------- 1. Recon & Information Gathering ----------
install_recon() {
    info "ติดตั้งกลุ่ม Recon / Information Gathering..."
    pkg install -y nmap whois
    pip install theHarvester dnsenum 2>/dev/null || true

    # whatweb
    if [ ! -d "$TOOLS_DIR/WhatWeb" ]; then
        git clone https://github.com/urbanadventurer/WhatWeb.git "$TOOLS_DIR/WhatWeb"
    fi

    # Sublist3r (subdomain enumeration)
    if [ ! -d "$TOOLS_DIR/Sublist3r" ]; then
        git clone https://github.com/aboul3la/Sublist3r.git "$TOOLS_DIR/Sublist3r"
        pip install -r "$TOOLS_DIR/Sublist3r/requirements.txt" 2>/dev/null || true
    fi

    # ProjectDiscovery tools (subfinder, httpx, nuclei, assetfinder)
    if command -v go >/dev/null 2>&1; then
        go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest 2>/dev/null || true
        go install github.com/projectdiscovery/httpx/cmd/httpx@latest 2>/dev/null || true
        go install github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest 2>/dev/null || true
        go install github.com/tomnomnom/assetfinder@latest 2>/dev/null || true
        go install github.com/tomnomnom/waybackurls@latest 2>/dev/null || true
    fi
    ok "กลุ่ม Recon ติดตั้งเสร็จ"
}

# ---------- 2. Web Vulnerability Scanners ----------
install_web() {
    info "ติดตั้งกลุ่ม Web Vulnerability Scanner..."
    # sqlmap
    if [ ! -d "$TOOLS_DIR/sqlmap" ]; then
        git clone --depth 1 https://github.com/sqlmapproject/sqlmap.git "$TOOLS_DIR/sqlmap"
    fi
    # nikto
    if [ ! -d "$TOOLS_DIR/nikto" ]; then
        git clone https://github.com/sullo/nikto.git "$TOOLS_DIR/nikto"
    fi
    # dirsearch
    pip install dirsearch 2>/dev/null || true
    # gobuster / ffuf
    pkg install -y gobuster 2>/dev/null || go install github.com/OJ/gobuster/v3@latest 2>/dev/null || true
    go install github.com/ffuf/ffuf@latest 2>/dev/null || true
    # WPScan (WordPress)
    gem install wpscan 2>/dev/null || warn "wpscan ติดตั้งไม่สำเร็จ (ต้องใช้ gem)"
    # JoomScan
    if [ ! -d "$TOOLS_DIR/joomscan" ]; then
        git clone https://github.com/OWASP/joomscan.git "$TOOLS_DIR/joomscan"
    fi
    # commix (command injection)
    if [ ! -d "$TOOLS_DIR/commix" ]; then
        git clone https://github.com/commixproject/commix.git "$TOOLS_DIR/commix"
    fi
    # XSStrike
    if [ ! -d "$TOOLS_DIR/XSStrike" ]; then
        git clone https://github.com/s0md3v/XSStrike.git "$TOOLS_DIR/XSStrike"
        pip install -r "$TOOLS_DIR/XSStrike/requirements.txt" 2>/dev/null || true
    fi
    # wfuzz
    pip install wfuzz 2>/dev/null || true
    ok "กลุ่ม Web Scanner ติดตั้งเสร็จ"
}

# ---------- 3. Brute Force & Password Attacks ----------
install_brute() {
    info "ติดตั้งกลุ่ม Brute Force / Password Attack..."
    pkg install -y hydra john 2>/dev/null || true
    # hash-identifier
    pip install hashid 2>/dev/null || true
    # crunch (wordlist generator)
    if [ ! -d "$TOOLS_DIR/crunch" ]; then
        git clone https://github.com/crunchsec/crunch.git "$TOOLS_DIR/crunch" 2>/dev/null || true
    fi
    # SecLists (wordlists collection)
    if [ ! -d "$TOOLS_DIR/SecLists" ]; then
        info "กำลังดาวน์โหลด SecLists (ขนาดใหญ่ ~300MB)..."
        git clone --depth 1 https://github.com/danielmiessler/SecLists.git "$TOOLS_DIR/SecLists" 2>/dev/null || warn "ดาวน์โหลด SecLists ไม่สำเร็จ"
    fi
    ok "กลุ่ม Brute Force ติดตั้งเสร็จ"
}

# ---------- 4. Exploitation Frameworks ----------
install_exploit() {
    info "ติดตั้งกลุ่ม Exploitation Framework..."
    # Metasploit (ตัวติดตั้งสำหรับ Termux)
    if [ ! -d "$HOME/metasploit-framework" ]; then
        warn "กำลังติดตั้ง Metasploit (ใช้พื้นที่และเวลามาก)..."
        pkg install -y ruby ruby-dev libffi-dev libssl-dev libxml2-dev libxslt-dev ncurses-dev make clang postgresql postgresql-contrib 2>/dev/null || true
        cd "$HOME"
        curl -LO https://github.com/termux/termux-packages/files/8334074/msf.txt 2>/dev/null || true
        # ใช้ installer ยอดนิยมสำหรับ Termux
        curl -fsSL https://raw.githubusercontent.com/gushmazuko/metasploit_in_termux/master/metasploit.sh -o "$TOOLS_DIR/metasploit_install.sh" 2>/dev/null && \
            bash "$TOOLS_DIR/metasploit_install.sh" || warn "Metasploit ติดตั้งไม่สำเร็จ ลองติดตั้งด้วยตนเอง"
        cd - >/dev/null
    fi
    # searchsploit (Exploit-DB)
    if [ ! -d "$TOOLS_DIR/exploitdb" ]; then
        git clone https://gitlab.com/exploit-database/exploitdb.git "$TOOLS_DIR/exploitdb" 2>/dev/null || true
    fi
    ok "กลุ่ม Exploitation ติดตั้งเสร็จ"
}

# ---------- 5. Network & Wireless ----------
install_network() {
    info "ติดตั้งกลุ่ม Network / Wireless..."
    pkg install -y tcpdump tor proxychains-ng macchanger 2>/dev/null || true
    pip install mitmproxy 2>/dev/null || true
    # bettercap (ต้องใช้ go)
    go install github.com/bettercap/bettercap@latest 2>/dev/null || warn "bettercap ติดตั้งไม่สำเร็จ"
    warn "หมายเหตุ: เครื่องมือ Wireless (aircrack-ng, reaver) ต้องการ Root + WiFi chip ที่รองรับ Monitor Mode"
    read -p "ต้องการติดตั้ง aircrack-ng (ต้อง Root)? [y/N]: " ans
    if [ "$ans" = "y" ] || [ "$ans" = "Y" ]; then
        pkg install -y aircrack-ng 2>/dev/null || warn "aircrack-ng ไม่มีใน repo หรือต้อง root"
    fi
    ok "กลุ่ม Network ติดตั้งเสร็จ"
}

# ---------- 6. Forensics & Analysis ----------
install_forensics() {
    info "ติดตั้งกลุ่ม Forensics / Analysis..."
    pkg install -y exiftool binwalk 2>/dev/null || true
    pip install binwalk 2>/dev/null || true
    # steghide (steganography)
    pkg install -y steghide 2>/dev/null || true
    # strings มีใน binutils แล้ว
    pkg install -y binutils file 2>/dev/null || true
    ok "กลุ่ม Forensics ติดตั้งเสร็จ"
}

# ---------- 7. Anonymity & Privacy (basic) ----------
install_anon() {
    info "ติดตั้งกลุ่ม Anonymity / Privacy (พื้นฐาน)..."
    pkg install -y tor proxychains-ng 2>/dev/null || true
    ok "ติดตั้ง tor + proxychains เสร็จ ใช้งาน: proxychains4 <command>"
}

# ---------- Full Install ----------
full_install() {
    base_setup
    install_recon
    install_web
    install_brute
    install_network
    install_forensics
    install_anon
    read -p "ต้องการติดตั้ง Metasploit ด้วยหรือไม่ (หนัก ~1GB)? [y/N]: " msf
    if [ "$msf" = "y" ] || [ "$msf" = "Y" ]; then
        install_exploit
    fi
}

# ---------- Menu ----------
show_menu() {
    clear
    echo -e "${BOLD}${CYAN}============================================================${NC}"
    echo -e "${BOLD}${CYAN}        Termux Security Testing Toolkit Installer           ${NC}"
    echo -e "${BOLD}${CYAN}============================================================${NC}"
    echo -e "  ${YELLOW}เครื่องมือทั้งหมดติดตั้งที่: $TOOLS_DIR${NC}"
    echo ""
    echo -e "  ${GREEN}[0]${NC} ติดตั้งทั้งหมด (Full Install) ${RED}(แนะนำสำหรับเครื่องที่มีพื้นที่เพียงพอ)${NC}"
    echo -e "  ${GREEN}[1]${NC} พื้นฐานระบบ (Base Setup)"
    echo -e "  ${GREEN}[2]${NC} Recon / Information Gathering (nmap, subfinder, theHarvester...)"
    echo -e "  ${GREEN}[3]${NC} Web Vulnerability Scanner (sqlmap, nikto, wpscan, XSStrike...)"
    echo -e "  ${GREEN}[4]${NC} Brute Force & Password (hydra, john, SecLists...)"
    echo -e "  ${GREEN}[5]${NC} Exploitation Framework (Metasploit, searchsploit)"
    echo -e "  ${GREEN}[6]${NC} Network & Wireless (tcpdump, mitmproxy, tor...)"
    echo -e "  ${GREEN}[7]${NC} Forensics & Analysis (exiftool, binwalk, steghide...)"
    echo -e "  ${GREEN}[8]${NC} Anonymity & Privacy (tor, proxychains)"
    echo -e "  ${GREEN}[9]${NC} ออกจากโปรแกรม"
    echo ""
    echo -e "${BOLD}============================================================${NC}"
    read -p "เลือกตัวเลือก [0-9]: " choice
    case $choice in
        0) full_install ;;
        1) base_setup ;;
        2) base_setup; install_recon ;;
        3) base_setup; install_web ;;
        4) base_setup; install_brute ;;
        5) base_setup; install_exploit ;;
        6) base_setup; install_network ;;
        7) base_setup; install_forensics ;;
        8) base_setup; install_anon ;;
        9) exit 0 ;;
        *) err "ตัวเลือกไม่ถูกต้อง"; sleep 1; show_menu ;;
    esac
}

# ---------- Main ----------
show_menu

echo ""
ok "============================================================"
ok "  ติดตั้งเสร็จสิ้น! เครื่องมืออยู่ที่: $TOOLS_DIR"
ok "  แนะนำให้เริ่มเรียนรู้จาก: TryHackMe / HackTheBox (Lab ที่ปลอดภัย)"
ok "  หรือเข้าร่วม Bug Bounty Program เพื่อทดสอบอย่างถูกกฎหมาย"
ok "============================================================"
echo ""
warn "⚠️  อย่าลืม: ใช้เครื่องมือเหล่านี้กับระบบที่คุณได้รับอนุญาตเท่านั้น"
