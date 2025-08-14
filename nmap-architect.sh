
#!/bin/bash

# Nmap Architect - Advanced Nmap Command Builder
# Version: 2.0.0
# Author: Muhammad Hassan
# Description: Interactive tool to build complex Nmap commands with ease
# GitHub: https://github.com/muhammad-hassan31144/nmap-architect

# Version information
NMAP_ARCHITECT_VERSION="2.0.0"
NMAP_ARCHITECT_BUILD="$(date '+%Y%m%d')"

# Global variable to accumulate Nmap arguments
nmap_args=""


# Function to add an option to the nmap_args
add_option() {
    local option="$1"
    local value="$2"
    
    # Check if the option already exists and remove it (to prevent duplicates)
    nmap_args=$(echo "$nmap_args" | sed -E "s/$option [^ ]* /$option $value /g")
    
    # If the option wasn't found and replaced, add it
    if ! echo "$nmap_args" | grep -q "$option"; then
        nmap_args="$nmap_args $option $value"
    fi
    
    # Trim extra spaces
    nmap_args=$(echo "$nmap_args" | sed -E 's/^ +| +$//g' | sed -E 's/ +/ /g')
    
    echo "Added option: $option $value"
}

# Function to add a flag to the nmap_args (no value)
add_flag() {
    local flag="$1"
    
    # Check if the flag already exists
    if ! echo "$nmap_args" | grep -q -w "$flag"; then
        nmap_args="$nmap_args $flag"
        # Trim extra spaces
        nmap_args=$(echo "$nmap_args" | sed -E 's/^ +| +$//g' | sed -E 's/ +/ /g')
        echo "Added flag: $flag"
    else
        echo "Flag already exists: $flag"
    fi
}

# Function to remove an option or flag from nmap_args
remove_option() {
    local option="$1"
    
    # Remove the option and its value
    nmap_args=$(echo "$nmap_args" | sed -E "s/$option [^ ]* / /g" | sed -E "s/$option / /g")
    
    # Trim extra spaces
    nmap_args=$(echo "$nmap_args" | sed -E 's/^ +| +$//g' | sed -E 's/ +/ /g')
    
    echo "Removed option: $option"
}

# Array to track active scan techniques
declare -A active_options

# Function to check if an option conflicts with already selected options
check_conflicts() {
    local new_option="$1"
    local category="$2"
    local mutually_exclusive="$3" # Array of options that can't coexist in this category
    
    # If this is a mutually exclusive category
    if [[ "$category" != "" ]]; then
        # Check if we already have an option in this category
        for option in $mutually_exclusive; do
            if [[ "$nmap_args" =~ $option && "$option" != "$new_option" ]]; then
                echo "Warning: $new_option conflicts with previously selected $option"
                read -p "Do you want to replace $option with $new_option? (y/n): " confirm
                if [[ "$confirm" == "y" ]]; then
                    remove_option "$option"
                    active_options["$option"]=""
                    active_options["$new_option"]="$new_option"
                    return 0
                else
                    return 1
                fi
            fi
        done
    fi
    
    # No conflicts found
    active_options["$new_option"]="$new_option"
    return 0
}

# Check if user has sudo privileges
check_sudo() {
    if [[ "$nmap_args" =~ -sS|-sU|-sY|-sZ|-sO|-sA|-sW|-sM|-sN|-sF|-sX|--scanflags|-O|--osscan ]]; then
        echo "Note: The options you selected require root privileges."
        if ! sudo -n true 2>/dev/null; then
            echo "You'll be prompted for your password when you run the scan."
        fi
    fi
}

# Function to show active options
show_active_options() {
    clear
    echo "================================================================="
    echo "                   ACTIVE NMAP OPTIONS                           "
    echo "================================================================="
    
    if [[ -z "$nmap_args" ]]; then
        echo "No options are currently selected."
    else
        echo "Current command: nmap $nmap_args"
        echo
        echo "Options by category:"
        
        # Display all active options grouped by category
        # Target Specification
        if [[ "$nmap_args" =~ -iL|--iL|-iR|--iR|--exclude|--excludefile ]]; then
            echo "- Target Specification: $(echo "$nmap_args" | grep -o '\-iL [^ ]*\|\-\-iL [^ ]*\|\-iR [^ ]*\|\-\-iR [^ ]*\|\-\-exclude [^ ]*\|\-\-excludefile [^ ]*')"
        fi
        
        # Host Discovery
        if [[ "$nmap_args" =~ -sL|-sn|-Pn|-PS|-PA|-PU|-PY|-PE|-PP|-PM ]]; then
            echo "- Host Discovery: $(echo "$nmap_args" | grep -o '\-sL\|\-sn\|\-Pn\|\-PS[^ ]*\|\-PA[^ ]*\|\-PU[^ ]*\|\-PY[^ ]*\|\-PE\|\-PP\|\-PM')"
        fi
        
        # Scan Techniques
        if [[ "$nmap_args" =~ -sS|-sT|-sA|-sW|-sM|-sU|-sN|-sF|-sX|--scanflags|-sI|-sY|-sZ|-sO|-b ]]; then
            echo "- Scan Techniques: $(echo "$nmap_args" | grep -o '\-sS\|\-sT\|\-sA\|\-sW\|\-sM\|\-sU\|\-sN\|\-sF\|\-sX\|\-\-scanflags [^ ]*\|\-sI [^ ]*\|\-sY\|\-sZ\|\-sO\|\-b [^ ]*')"
        fi
        
        # Port Specification
        if [[ "$nmap_args" =~ -p|--exclude-ports|-F|-r|--top-ports|--port-ratio ]]; then
            echo "- Port Specification: $(echo "$nmap_args" | grep -o '\-p [^ ]*\|\-\-exclude-ports [^ ]*\|\-F\|\-r\|\-\-top-ports [^ ]*\|\-\-port-ratio [^ ]*')"
        fi
        
        # Service/Version Detection
        if [[ "$nmap_args" =~ -sV|--version-intensity|--version-light|--version-all|--version-trace ]]; then
            echo "- Service Detection: $(echo "$nmap_args" | grep -o '\-sV\|\-\-version-intensity [^ ]*\|\-\-version-light\|\-\-version-all\|\-\-version-trace')"
        fi
        
        # OS Detection
        if [[ "$nmap_args" =~ -O|--osscan-limit|--osscan-guess ]]; then
            echo "- OS Detection: $(echo "$nmap_args" | grep -o '\-O\|\-\-osscan-limit\|\-\-osscan-guess')"
        fi
        
        # Timing and Performance
        if [[ "$nmap_args" =~ -T|-T[0-5]|--min-hostgroup|--max-hostgroup|--min-parallelism|--max-parallelism|--min-rtt-timeout|--max-rtt-timeout|--initial-rtt-timeout|--max-retries|--host-timeout|--scan-delay|--max-scan-delay|--min-rate|--max-rate ]]; then
            echo "- Timing and Performance: $(echo "$nmap_args" | grep -o '\-T[0-5]\|\-\-min-hostgroup [^ ]*\|\-\-max-hostgroup [^ ]*\|\-\-min-parallelism [^ ]*\|\-\-max-parallelism [^ ]*\|\-\-min-rtt-timeout [^ ]*\|\-\-max-rtt-timeout [^ ]*\|\-\-initial-rtt-timeout [^ ]*\|\-\-max-retries [^ ]*\|\-\-host-timeout [^ ]*\|\-\-scan-delay [^ ]*\|\-\-max-scan-delay [^ ]*\|\-\-min-rate [^ ]*\|\-\-max-rate [^ ]*')"
        fi
        
        # Firewall/IDS Evasion
        if [[ "$nmap_args" =~ --mtu|-D|-S|-e|-g|--source-port|--proxies|--data|--data-string|--data-length|--ip-options|--ttl|--spoof-mac|--badsum ]]; then
            echo "- Firewall/IDS Evasion: $(echo "$nmap_args" | grep -o '\-\-mtu [^ ]*\|\-D [^ ]*\|\-S [^ ]*\|\-e [^ ]*\|\-g [^ ]*\|\-\-source-port [^ ]*\|\-\-proxies [^ ]*\|\-\-data [^ ]*\|\-\-data-string [^ ]*\|\-\-data-length [^ ]*\|\-\-ip-options [^ ]*\|\-\-ttl [^ ]*\|\-\-spoof-mac [^ ]*\|\-\-badsum')"
        fi
        
        # Output Options
        if [[ "$nmap_args" =~ -oN|-oX|-oS|-oG|-oA|-v|-vv|-d|-dd|--packet-trace|--reason|--stylesheet|--resume|--append-output|--noninteractive ]]; then
            echo "- Output Options: $(echo "$nmap_args" | grep -o '\-oN [^ ]*\|\-oX [^ ]*\|\-oS [^ ]*\|\-oG [^ ]*\|\-oA [^ ]*\|\-v\|\-vv\|\-d\|\-dd\|\-\-packet-trace\|\-\-reason\|\-\-stylesheet [^ ]*\|\-\-resume [^ ]*\|\-\-append-output\|\-\-noninteractive')"
        fi
        
        # Misc Options
        if [[ "$nmap_args" =~ -6|-A|--datadir|--send-eth|--send-ip|--privileged|--unprivileged|-V ]]; then
            echo "- Misc Options: $(echo "$nmap_args" | grep -o '\-6\|\-A\|\-\-datadir [^ ]*\|\-\-send-eth\|\-\-send-ip\|\-\-privileged\|\-\-unprivileged\|\-V')"
        fi
    fi
    
    echo "================================================================="
    read -p "Press Enter to continue..."
}

# Function to display help information
display_help() {
    clear
    echo "╔═══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                      🆘 NMAP ARCHITECT HELP SYSTEM 🆘                        ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════════╝"
    echo
    echo "📖 ABOUT NMAP ARCHITECT v$NMAP_ARCHITECT_VERSION"
    echo "═══════════════════════════════════════════════════════════════"
    echo "Advanced interactive Nmap command builder for network reconnaissance,"
    echo "penetration testing, and security auditing. Build complex scans with ease!"
    echo
    echo "🚀 USAGE: $0 [OPTIONS]"
    echo
    echo "🛠️  COMMAND LINE OPTIONS:"
    echo "  -h, --help           Display this help menu and exit"
    echo
    echo "🎯 MAIN MENU OVERVIEW:"
    echo "═══════════════════════════════════════════════════════════════"
    echo
    echo "🚀 QUICK START:"
    echo "  📋 Scan Templates       - Pre-built configurations for common scenarios"
    echo "  🎯 Target Specification - Define what to scan (IPs, networks, files)"
    echo
    echo "🔍 DISCOVERY & SCANNING:"
    echo "  📡 Host Discovery       - Find live hosts (ping sweeps, ARP, etc.)"
    echo "  🔓 Scan Techniques      - Choose scan methods (SYN, Connect, UDP, etc.)"
    echo "  🔌 Port Specification   - Configure port ranges and scanning order"
    echo "  🔬 Service Detection    - Identify services and their versions"
    echo "  🖥️  OS Detection        - Operating system fingerprinting"
    echo
    echo "🔬 ADVANCED FEATURES:"
    echo "  🧪 NSE Script Engine    - Vulnerability detection and advanced analysis"
    echo "  ⏱️  Timing & Performance - Speed vs stealth optimization"
    echo "  🛡️  Firewall Evasion    - Bypass firewalls and intrusion detection"
    echo
    echo "⚙️  CONFIGURATION:"
    echo "  🔧 Miscellaneous        - Additional Nmap options and settings"
    echo "  📄 Output Configuration - Results formatting and file output"
    echo
    echo "🎯 GETTING STARTED:"
    echo "═══════════════════════════════════════════════════════════════"
    echo "1. 🎯 New users: Start with 'Scan Templates' for quick setup"
    echo "2. 🔧 Advanced users: Build custom scans using individual menus"
    echo "3. 👁️  Always review your command before execution"
    echo "4. 🛡️  Ensure you have permission to scan target systems"
    echo
    echo "⚠️  IMPORTANT SECURITY NOTES:"
    echo "═══════════════════════════════════════════════════════════════"
    echo "• Only scan systems you own or have explicit permission to test"
    echo "• Some scan types require root/administrator privileges"
    echo "• Aggressive scans may trigger security alerts"
    echo "• Be mindful of network impact and timing"
    echo "• Follow responsible disclosure for any vulnerabilities found"
    echo
    echo "🔗 RESOURCES:"
    echo "═══════════════════════════════════════════════════════════════"
    echo "• Official Nmap documentation: https://nmap.org/docs.html"
    echo "• NSE Script documentation: https://nmap.org/nsedoc/"
    echo "• Nmap Architect GitHub: https://github.com/nmap-architect/nmap-architect"
    echo
    echo "💡 Quick Tips:"
    echo "• Type 'tips' at any menu for scanning best practices"
    echo "• Use 'Ctrl+C' to interrupt long-running operations"
    echo "• Templates are great starting points for complex scans"
    echo
    read -p "Press Enter to return to the main menu..."
}

# Tips and Best Practices
show_tips() {
    clear
    echo "💡 NMAP SCANNING TIPS & BEST PRACTICES"
    echo "═══════════════════════════════════════════════════════════════"
    echo
    echo "🎯 TARGET SELECTION:"
    echo "• Always verify you have permission to scan targets"
    echo "• Use CIDR notation for network ranges (e.g., 192.168.1.0/24)"
    echo "• Consider using --exclude to skip sensitive systems"
    echo "• Test on a small range first, then scale up"
    echo
    echo "🚀 SCAN PERFORMANCE:"
    echo "• Use -T4 for faster scans on reliable networks"
    echo "• Use -T2 or -T1 for stealth and unreliable connections"
    echo "• Adjust --min-rate and --max-rate for speed control"
    echo "• Use -F for fast scans of top 100 ports only"
    echo
    echo "🛡️  STEALTH & EVASION:"
    echo "• Combine multiple evasion techniques for better results"
    echo "• Use decoys (-D) to blend in with legitimate traffic"
    echo "• Fragment packets (--mtu) to evade simple firewalls"
    echo "• Randomize scan order (--randomize-hosts) to avoid patterns"
    echo
    echo "🔍 DISCOVERY STRATEGIES:"
    echo "• Start with host discovery (-sn) to map the network"
    echo "• Use multiple ping types (-PE -PP -PM) for better coverage"
    echo "• Disable ping (-Pn) only when necessary (slower but thorough)"
    echo "• Consider ARP scan (-PR) for local network segments"
    echo
    echo "🧪 NSE SCRIPT USAGE:"
    echo "• Start with 'safe' scripts to avoid service disruption"
    echo "• Use specific scripts rather than broad categories when possible"
    echo "• Test scripts in lab environments before production use"
    echo "• Read script documentation for required arguments"
    echo
    echo "📊 OUTPUT & DOCUMENTATION:"
    echo "• Always save results using -oA for all formats"
    echo "• Use descriptive filenames with timestamps"
    echo "• Keep separate directories for different projects"
    echo "• Document your methodology for repeatable results"
    echo
    echo "⚠️  LEGAL & ETHICAL CONSIDERATIONS:"
    echo "• Only scan systems you own or have written permission to test"
    echo "• Follow responsible disclosure for vulnerabilities found"
    echo "• Be aware of local laws regarding security testing"
    echo "• Consider network impact and bandwidth usage"
    echo "• Inform network administrators of planned security testing"
    echo
    echo "🔧 TROUBLESHOOTING:"
    echo "• Use -d for debugging output if scans aren't working"
    echo "• Check firewall rules if getting unexpected results"
    echo "• Verify target reachability with basic ping first"
    echo "• Use --packet-trace for detailed packet analysis"
    echo
    read -p "Press Enter to continue..."
}

# Function to display introduction banner
display_banner() {
    clear
    echo "╔═══════════════════════════════════════════════════════════════════════════════╗"
    echo "║  _   _ __  __    _    ____     _             _     _ _            _            ║"
    echo "║ | \ | |  \/  |  / \  |  _ \   / \   _ __ ___| |__ (_) |_ ___  ___| |_          ║"
    echo "║ |  \| | |\/| | / _ \ | |_) | / _ \ | '__/ __| '_ \| | __/ _ \/ __| __|         ║"
    echo "║ | |\  | |  | |/ ___ \|  __/ / ___ \| | | (__| | | | | ||  __/ (__| |_          ║"
    echo "║ |_| \_|_|  |_/_/   \_\_|   /_/   \_\_|  \___|_| |_|_|\__\___|\___|\__|         ║"
    echo "║                                                                               ║"
    echo "║                     🛡️  Advanced Nmap Command Builder  🛡️                     ║"
    echo "║                         Build Professional Scans with Ease                   ║"
    echo "║                                                                               ║"
    echo "║  Version: $NMAP_ARCHITECT_VERSION                               Build: $NMAP_ARCHITECT_BUILD      ║"
    echo "║                                                                               ║"
    echo "║  💡 Master Network Reconnaissance • 🔍 Discover Hidden Services              ║"
    echo "║  🛡️  Evade Firewalls & IDS        • 📊 Generate Professional Reports        ║"
    echo "║                                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════════╝"
    echo
    echo "🚀 Welcome, Network Architect! Ready to build your perfect scan?"
    echo "💡 Type '-h' or '--help' at any time for guidance"
    echo "📖 Use scan templates for quick starts or build custom scans step by step"
    echo
}

# Function to handle invalid input
invalid_input() {
    echo "Invalid input. Please select a valid option."
    sleep 1
}

# Function to return to the main menu
return_to_menu() {
    echo "Returning to the main menu..."
    sleep 1
}

# Ensure Nmap is installed
check_nmap_installed() {
    if ! command -v nmap &> /dev/null; then
        echo "Error: Nmap is not installed. Please install it and rerun the script."
        exit 1
    fi
}

# Helper function to prompt for input
prompt_input() {
    local prompt="$1"
    local var_name="$2"
    read -p "$prompt" "$var_name"
}

# ==========================
# SECTION: Scan Templates
# ==========================

# Function to display and select scan templates
configure_scan_templates() {
    while true; do
        clear
        echo "🎯 SCAN TEMPLATES - Quick Start Your Network Reconnaissance"
        echo "═══════════════════════════════════════════════════════════════"
        echo
        echo "📋 DISCOVERY & RECONNAISSANCE:"
        echo "1.  🔍 Quick Host Discovery       - Fast ping sweep and basic port check"
        echo "2.  🌐 Network Topology Scan     - Comprehensive network mapping"
        echo "3.  🕵️  Stealth Reconnaissance    - Low-profile information gathering"
        echo
        echo "🔓 PENETRATION TESTING:"
        echo "4.  ⚡ Fast Port Scan            - Quick TCP port enumeration"
        echo "5.  🛡️  Stealth Port Scan         - Evade basic firewall detection"
        echo "6.  🔬 Comprehensive Scan        - Deep analysis with version detection"
        echo "7.  🎯 Vulnerability Assessment  - Security-focused scanning"
        echo
        echo "🌍 WEB & SERVICES:"
        echo "8.  🌐 Web Application Scan      - HTTP/HTTPS service analysis"
        echo "9.  📧 Mail Server Analysis      - SMTP/POP3/IMAP enumeration"
        echo "10. 🖥️  Remote Access Scan       - SSH/RDP/VNC detection"
        echo
        echo "🏢 ENTERPRISE & SPECIALIZED:"
        echo "11. 🏢 Internal Network Audit    - Comprehensive internal scanning"
        echo "12. 🌐 External Perimeter Scan   - Public-facing service enumeration"
        echo "13. 🖨️  Device Discovery Scan     - Printers, IoT, embedded devices"
        echo "14. ☁️  Cloud Infrastructure     - Cloud service enumeration"
        echo
        echo "⚙️  ADVANCED & CUSTOM:"
        echo "15. 🎛️  Custom Template Builder   - Create your own template"
        echo "16. 📂 Load Saved Template       - Import previously saved configuration"
        echo "17. ⬅️  Back to Main Menu"
        echo
        echo "═══════════════════════════════════════════════════════════════"
        read -p "🚀 Select a template to launch your reconnaissance mission: " template_choice

        case $template_choice in
        1)
            apply_quick_discovery_template
            ;;
        2)
            apply_network_topology_template
            ;;
        3)
            apply_stealth_recon_template
            ;;
        4)
            apply_fast_port_scan_template
            ;;
        5)
            apply_stealth_port_scan_template
            ;;
        6)
            apply_comprehensive_scan_template
            ;;
        7)
            apply_vulnerability_assessment_template
            ;;
        8)
            apply_web_application_template
            ;;
        9)
            apply_mail_server_template
            ;;
        10)
            apply_remote_access_template
            ;;
        11)
            apply_internal_audit_template
            ;;
        12)
            apply_external_perimeter_template
            ;;
        13)
            apply_device_discovery_template
            ;;
        14)
            apply_cloud_infrastructure_template
            ;;
        15)
            create_custom_template
            ;;
        16)
            load_saved_template
            ;;
        17)
            return_to_menu
            break
            ;;
        "-h"|"--help")
            display_template_help
            ;;
        *)
            invalid_input
            ;;
        esac
        read -p "Press Enter to continue..."
    done
}

# Template application functions
apply_quick_discovery_template() {
    nmap_args="-sn --dns-servers 8.8.8.8,1.1.1.1"
    echo "✅ Quick Host Discovery template applied!"
    echo "📋 Configuration: Ping sweep with DNS resolution"
    echo "🎯 Use case: Quickly find live hosts on a network"
    echo "⚡ Speed: Very Fast"
    echo
    echo "Current command: nmap $nmap_args [target]"
}

apply_network_topology_template() {
    nmap_args="-sn -PE -PP -PM -PO --traceroute --dns-servers 8.8.8.8,1.1.1.1"
    echo "✅ Network Topology Scan template applied!"
    echo "📋 Configuration: Multiple ping types with traceroute"
    echo "🎯 Use case: Map network topology and routing paths"
    echo "⚡ Speed: Medium"
    echo
    echo "Current command: nmap $nmap_args [target]"
}

apply_stealth_recon_template() {
    nmap_args="-sn -PE --disable-arp-ping -T2 --randomize-hosts"
    echo "✅ Stealth Reconnaissance template applied!"
    echo "📋 Configuration: Low-profile host discovery"
    echo "🎯 Use case: Avoid detection during initial reconnaissance"
    echo "⚡ Speed: Slow (by design)"
    echo
    echo "Current command: nmap $nmap_args [target]"
}

apply_fast_port_scan_template() {
    nmap_args="-sS -F --min-rate 1000 -T4"
    echo "✅ Fast Port Scan template applied!"
    echo "📋 Configuration: SYN scan on top 100 ports"
    echo "🎯 Use case: Quick port enumeration"
    echo "⚡ Speed: Very Fast"
    echo "⚠️  Note: Requires root privileges"
    echo
    echo "Current command: nmap $nmap_args [target]"
}

apply_stealth_port_scan_template() {
    nmap_args="-sS -p- -T2 --scan-delay 500ms --randomize-hosts -D RND:5"
    echo "✅ Stealth Port Scan template applied!"
    echo "📋 Configuration: Slow SYN scan with decoys and delays"
    echo "🎯 Use case: Evade basic firewall and IDS detection"
    echo "⚡ Speed: Very Slow (by design)"
    echo "⚠️  Note: Requires root privileges"
    echo
    echo "Current command: nmap $nmap_args [target]"
}

apply_comprehensive_scan_template() {
    nmap_args="-sS -sV -O -A --script=default -p- -T4"
    echo "✅ Comprehensive Scan template applied!"
    echo "📋 Configuration: Full port range with OS/service detection"
    echo "🎯 Use case: Complete system analysis and enumeration"
    echo "⚡ Speed: Slow"
    echo "⚠️  Note: Requires root privileges, generates significant traffic"
    echo
    echo "Current command: nmap $nmap_args [target]"
}

apply_vulnerability_assessment_template() {
    nmap_args="-sS -sV --script=vuln,auth,brute -p- -T3"
    echo "✅ Vulnerability Assessment template applied!"
    echo "📋 Configuration: Security-focused scanning with vuln scripts"
    echo "🎯 Use case: Identify potential security vulnerabilities"
    echo "⚡ Speed: Medium-Slow"
    echo "⚠️  Note: May trigger security alerts, use responsibly"
    echo
    echo "Current command: nmap $nmap_args [target]"
}

apply_web_application_template() {
    nmap_args="-sS -sV --script=http-* -p 80,443,8080,8443,8000,8888,9000 -T4"
    echo "✅ Web Application Scan template applied!"
    echo "📋 Configuration: Web-focused scanning with HTTP scripts"
    echo "🎯 Use case: Analyze web servers and applications"
    echo "⚡ Speed: Medium"
    echo
    echo "Current command: nmap $nmap_args [target]"
}

apply_mail_server_template() {
    nmap_args="-sS -sV --script=smtp-*,pop3-*,imap-* -p 25,110,143,465,587,993,995 -T4"
    echo "✅ Mail Server Analysis template applied!"
    echo "📋 Configuration: Mail service enumeration and testing"
    echo "🎯 Use case: Analyze email server configurations"
    echo "⚡ Speed: Medium"
    echo
    echo "Current command: nmap $nmap_args [target]"
}

apply_remote_access_template() {
    nmap_args="-sS -sV --script=ssh-*,rdp-*,vnc-* -p 22,3389,5900,5901,5902,23 -T4"
    echo "✅ Remote Access Scan template applied!"
    echo "📋 Configuration: Remote administration service analysis"
    echo "🎯 Use case: Identify remote access services and configurations"
    echo "⚡ Speed: Medium"
    echo
    echo "Current command: nmap $nmap_args [target]"
}

apply_internal_audit_template() {
    nmap_args="-sS -sV -O --script=default,discovery,safe -p- --exclude-ports 1-20 -T3"
    echo "✅ Internal Network Audit template applied!"
    echo "📋 Configuration: Comprehensive internal network scanning"
    echo "🎯 Use case: Security audit of internal infrastructure"
    echo "⚡ Speed: Slow"
    echo "⚠️  Note: Designed for internal networks you own/manage"
    echo
    echo "Current command: nmap $nmap_args [target]"
}

apply_external_perimeter_template() {
    nmap_args="-sS -sV --top-ports 1000 --script=banner,http-title -T3 --randomize-hosts"
    echo "✅ External Perimeter Scan template applied!"
    echo "📋 Configuration: External-facing service enumeration"
    echo "🎯 Use case: Assess public-facing security posture"
    echo "⚡ Speed: Medium"
    echo "⚠️  Note: Only scan systems you own or have permission to test"
    echo
    echo "Current command: nmap $nmap_args [target]"
}

apply_device_discovery_template() {
    nmap_args="-sS -sV --script=snmp-*,upnp-* -p 161,1900,8080,80,443,23,22,515,9100 -T4"
    echo "✅ Device Discovery Scan template applied!"
    echo "📋 Configuration: IoT, printer, and embedded device detection"
    echo "🎯 Use case: Inventory network devices and appliances"
    echo "⚡ Speed: Medium"
    echo
    echo "Current command: nmap $nmap_args [target]"
}

apply_cloud_infrastructure_template() {
    nmap_args="-sS -sV --script=cloud-*,ssl-*,http-title --top-ports 100 -T4"
    echo "✅ Cloud Infrastructure template applied!"
    echo "📋 Configuration: Cloud service and SSL certificate analysis"
    echo "🎯 Use case: Assess cloud infrastructure and services"
    echo "⚡ Speed: Medium"
    echo
    echo "Current command: nmap $nmap_args [target]"
}

create_custom_template() {
    echo "🎛️ Custom Template Builder"
    echo "═════════════════════════════"
    echo "Build your own scan template by selecting individual components:"
    echo
    echo "This will take you through the regular menu system."
    echo "After configuring your scan, you can save it as a template."
    echo
    echo "Continue to main menu to build your custom scan..."
    sleep 2
}

load_saved_template() {
    echo "📂 Load Saved Template"
    echo "═══════════════════════"
    echo "Feature coming soon: Load previously saved scan configurations"
    echo "This will allow you to save and reuse complex scan setups."
    sleep 2
}

display_template_help() {
    clear
    echo "🆘 SCAN TEMPLATES HELP"
    echo "═══════════════════════════════════════════════════════════════"
    echo
    echo "📖 WHAT ARE SCAN TEMPLATES?"
    echo "Scan templates are pre-configured Nmap command combinations"
    echo "designed for specific use cases. They save time and ensure"
    echo "you're using appropriate scan techniques for your objectives."
    echo
    echo "🎯 CHOOSING THE RIGHT TEMPLATE:"
    echo
    echo "🔍 DISCOVERY TEMPLATES - Use when you need to:"
    echo "   • Find live hosts on a network"
    echo "   • Map network topology"
    echo "   • Perform stealthy reconnaissance"
    echo
    echo "🔓 PENETRATION TESTING - Use when you need to:"
    echo "   • Quickly enumerate open ports"
    echo "   • Perform comprehensive security analysis"
    echo "   • Identify vulnerabilities"
    echo
    echo "🌐 SERVICE-SPECIFIC - Use when targeting:"
    echo "   • Web applications and HTTP services"
    echo "   • Mail servers (SMTP, POP3, IMAP)"
    echo "   • Remote access services (SSH, RDP)"
    echo
    echo "🏢 ENTERPRISE SCANNING - Use for:"
    echo "   • Internal network security audits"
    echo "   • External perimeter assessments"
    echo "   • Device and asset discovery"
    echo
    echo "⚠️  IMPORTANT NOTES:"
    echo "   • Always ensure you have permission to scan target systems"
    echo "   • Some templates require root/administrator privileges"
    echo "   • Consider network impact and scan timing"
    echo "   • Templates can be customized after application"
    echo
    echo "💡 TIP: Start with a template closest to your needs,"
    echo "        then customize using the individual menus!"
    echo
    read -p "Press Enter to return to template selection..."
}


# ==========================
# SECTION: Menu Functions
# ==========================
configure_target_specification() {
    local target_specified=false
    
    while true; do
        clear
        echo "Target Specification Menu:"
        echo "1. Input single IP/hostname"
        echo "2. Input from list of hosts/networks (-iL)"
        echo "3. Choose random targets (-iR)"
        echo "4. Exclude hosts/networks (--exclude)"
        echo "5. Exclude list from file (--excludefile)"
        echo "6. Reset target options"
        echo "7. Go back to Main Menu"
        echo
        echo "Current target options: $(filter_nmap_args '([0-9]{1,3}\.){3}[0-9]{1,3}|[a-zA-Z0-9\.-]+|-iL|--exclude|--excludefile|-iR')"
        echo
        
        # Check if there are any target options
        if ! $target_specified && [[ "$nmap_args" != *"[0-9]"* && "$nmap_args" != *"-iL"* && "$nmap_args" != *"-iR"* ]]; then
            echo "WARNING: No target specified. Nmap requires at least one target specification."
            echo
        fi
        
        read -p "Select an option: " choice
        
        case $choice in
        1)
            prompt_input "Enter target IP address or hostname: " target
            if [[ -n "$target" ]]; then
                # Check if there are already explicit targets
                if [[ "$nmap_args" =~ ([0-9]{1,3}\.){3}[0-9]{1,3}|[a-zA-Z0-9\.-]+ && "$nmap_args" != *"-iL"* && "$nmap_args" != *"-iR"* ]]; then
                    echo "Warning: There appears to be existing targets. Adding a new target will scan both."
                    read -p "Continue? (y/n): " confirm
                    if [[ "$confirm" != "y" ]]; then
                        continue
                    fi
                fi
                
                nmap_args+=" $target"
                target_specified=true
                echo "Added target: $target"
            else
                echo "Error: Target cannot be empty."
            fi
            ;;
        2)
            prompt_input "Enter filename containing target hosts/networks: " filename
            if [[ -f "$filename" ]]; then
                # Check for existing targets
                if [[ "$nmap_args" =~ ([0-9]{1,3}\.){3}[0-9]{1,3}|[a-zA-Z0-9\.-]+ || "$nmap_args" == *"-iL"* || "$nmap_args" == *"-iR"* ]]; then
                    echo "Warning: There appears to be existing targets. Adding a target file will override them."
                    read -p "Continue? (y/n): " confirm
                    if [[ "$confirm" != "y" ]]; then
                        continue
                    fi
                    
                    # Remove existing targets
                    nmap_args=$(echo "$nmap_args" | sed -E 's/-iL [^ ]+//g' | sed -E 's/-iR [0-9]+//g' | sed 's/  / /g')
                    # Also try to remove IP addresses/hostnames (this is simplistic but helps)
                    nmap_args=$(echo "$nmap_args" | sed -E 's/([0-9]{1,3}\.){3}[0-9]{1,3}//g' | sed -E 's/[a-zA-Z0-9][a-zA-Z0-9\.-]+//g' | sed 's/  / /g')
                fi
                
                nmap_args+=" -iL $filename"
                target_specified=true
                echo "Added: -iL $filename"
            else
                echo "Error: File '$filename' not found!"
                echo "Note: If the file is in the same directory as this script, simply use the filename (e.g., 'targets.txt')."
            fi
            ;;
        3)
            prompt_input "Enter the number of random hosts to scan: " num_hosts
            if [[ "$num_hosts" =~ ^[0-9]+$ && "$num_hosts" -gt 0 ]]; then
                # Check for existing targets
                if [[ "$nmap_args" =~ ([0-9]{1,3}\.){3}[0-9]{1,3}|[a-zA-Z0-9\.-]+ || "$nmap_args" == *"-iL"* || "$nmap_args" == *"-iR"* ]]; then
                    echo "Warning: There appears to be existing targets. Random targets will override them."
                    read -p "Continue? (y/n): " confirm
                    if [[ "$confirm" != "y" ]]; then
                        continue
                    fi
                    
                    # Remove existing targets
                    nmap_args=$(echo "$nmap_args" | sed -E 's/-iL [^ ]+//g' | sed -E 's/-iR [0-9]+//g' | sed 's/  / /g')
                    # Also try to remove IP addresses/hostnames (this is simplistic but helps)
                    nmap_args=$(echo "$nmap_args" | sed -E 's/([0-9]{1,3}\.){3}[0-9]{1,3}//g' | sed -E 's/[a-zA-Z0-9][a-zA-Z0-9\.-]+//g' | sed 's/  / /g')
                fi
                
                nmap_args+=" -iR $num_hosts"
                target_specified=true
                echo "Added: -iR $num_hosts"
            else
                echo "Error: Number of hosts must be a positive integer."
            fi
            ;;
        4)
            prompt_input "Enter hosts/networks to exclude (comma-separated): " exclude_list
            if [[ -n "$exclude_list" ]]; then
                # Remove any existing exclude option
                nmap_args=$(echo "$nmap_args" | sed -E 's/--exclude [^ ]+//g' | sed 's/  / /g')
                
                nmap_args+=" --exclude $exclude_list"
                echo "Added: --exclude $exclude_list"
            else
                echo "Error: Exclude list cannot be empty."
            fi
            ;;
        5)
            prompt_input "Enter filename containing exclude list: " exclude_file
            if [[ -f "$exclude_file" ]]; then
                # Remove any existing exclude file option
                nmap_args=$(echo "$nmap_args" | sed -E 's/--excludefile [^ ]+//g' | sed 's/  / /g')
                
                nmap_args+=" --excludefile $exclude_file"
                echo "Added: --excludefile $exclude_file"
            else
                echo "Error: File '$exclude_file' not found!"
                echo "Note: If the file is in the same directory as this script, simply use the filename (e.g., 'excludes.txt')."
            fi
            ;;
        6)
            # Reset all target options
            nmap_args=$(echo "$nmap_args" | sed -E 's/-iL [^ ]+//g' | sed -E 's/-iR [0-9]+//g' | sed -E 's/--exclude [^ ]+//g' | sed -E 's/--excludefile [^ ]+//g' | sed 's/  / /g')
            # Also try to remove IP addresses/hostnames (this is simplistic but helps)
            nmap_args=$(echo "$nmap_args" | sed -E 's/([0-9]{1,3}\.){3}[0-9]{1,3}//g' | sed -E 's/[a-zA-Z0-9][a-zA-Z0-9\.-]+//g' | sed 's/  / /g')
            target_specified=false
            echo "All target options have been reset."
            ;;
        7)
            return_to_menu
            break
            ;;
        "-h"|"--help")
            display_help
            ;;
        *)
            invalid_input
            ;;
        esac
        read -p "Press Enter to continue..."
    done
}


# Host Discovery Menu
configure_host_discovery() {
    local ping_option_set=false
    
    while true; do
        clear
        echo "Host Discovery Menu:"
        echo "1. List Scan (-sL)"
        echo "2. Ping Scan (-sn)"
        echo "3. Treat all hosts as online (-Pn)"
        echo "4. TCP SYN/ACK, UDP, or SCTP discovery to given ports (-PS/PA/PU/PY)"
        echo "5. ICMP echo, timestamp, and netmask request probes (-PE/PP/PM)"
        echo "6. Reset discovery options"
        echo "7. Go back to Main Menu"
        echo
        echo "Current discovery options: $(filter_nmap_args '-sL|-sn|-P[nEPM]|-P[SAUY]')"
        echo
        
        # Check for conflicts
        if [[ "$nmap_args" == *"-sL"* && ("$nmap_args" == *"-sn"* || "$nmap_args" == *"-Pn"*) ]]; then
            echo "WARNING: Conflicting options detected. List scan (-sL) with ping scan (-sn) or no ping (-Pn)."
            echo "This may produce unexpected results."
            echo
        fi
        
        read -p "Select an option: " choice

        case $choice in
        1)
            # Check for conflicting options
            if [[ "$nmap_args" == *"-sn"* || "$nmap_args" == *"-Pn"* ]]; then
                echo "Warning: List scan (-sL) conflicts with other ping options (-sn, -Pn)."
                read -p "Continue anyway? (y/n): " confirm
                if [[ "$confirm" != "y" ]]; then
                    continue
                fi
            fi
            
            # Remove any existing list scan option
            nmap_args=$(echo "$nmap_args" | sed -E 's/-sL//g' | sed 's/  / /g')
            
            nmap_args+=" -sL"
            ping_option_set=true
            echo "Added: -sL"
            ;;
        2)
            # Check for conflicting options
            if [[ "$nmap_args" == *"-sL"* || "$nmap_args" == *"-Pn"* ]]; then
                echo "Warning: Ping scan (-sn) conflicts with other ping options (-sL, -Pn)."
                read -p "Continue anyway? (y/n): " confirm
                if [[ "$confirm" != "y" ]]; then
                    continue
                fi
            fi
            
            # Remove any existing ping scan option
            nmap_args=$(echo "$nmap_args" | sed -E 's/-sn//g' | sed 's/  / /g')
            
            nmap_args+=" -sn"
            ping_option_set=true
            echo "Added: -sn"
            ;;
        3)
            # Check for conflicting options
            if [[ "$nmap_args" == *"-sL"* || "$nmap_args" == *"-sn"* ]]; then
                echo "Warning: No ping (-Pn) conflicts with other ping options (-sL, -sn)."
                read -p "Continue anyway? (y/n): " confirm
                if [[ "$confirm" != "y" ]]; then
                    continue
                fi
            fi
            
            # Remove any existing no ping option
            nmap_args=$(echo "$nmap_args" | sed -E 's/-Pn//g' | sed 's/  / /g')
            
            nmap_args+=" -Pn"
            ping_option_set=true
            echo "Added: -Pn"
            ;;
        4)
            prompt_input "Enter port list for discovery (e.g., 22,80,443): " ports
            if [[ -n "$ports" ]]; then
                clear
                echo "Select discovery type for ports: $ports"
                echo "1. TCP SYN (-PS)"
                echo "2. TCP ACK (-PA)"
                echo "3. UDP (-PU)"
                echo "4. SCTP (-PY)"
                read -p "Choose a discovery type: " type_choice
                case $type_choice in
                1)
                    # Remove any existing TCP SYN discovery option
                    nmap_args=$(echo "$nmap_args" | sed -E 's/-PS[0-9,]+//g' | sed 's/  / /g')
                    
                    nmap_args+=" -PS$ports"
                    ping_option_set=true
                    echo "Added: -PS$ports"
                    ;;
                2)
                    # Remove any existing TCP ACK discovery option
                    nmap_args=$(echo "$nmap_args" | sed -E 's/-PA[0-9,]+//g' | sed 's/  / /g')
                    
                    nmap_args+=" -PA$ports"
                    ping_option_set=true
                    echo "Added: -PA$ports"
                    ;;
                3)
                    # Remove any existing UDP discovery option
                    nmap_args=$(echo "$nmap_args" | sed -E 's/-PU[0-9,]+//g' | sed 's/  / /g')
                    
                    nmap_args+=" -PU$ports"
                    ping_option_set=true
                    echo "Added: -PU$ports"
                    ;;
                4)
                    # Remove any existing SCTP discovery option
                    nmap_args=$(echo "$nmap_args" | sed -E 's/-PY[0-9,]+//g' | sed 's/  / /g')
                    
                    nmap_args+=" -PY$ports"
                    ping_option_set=true
                    echo "Added: -PY$ports"
                    ;;
                *)
                    echo "Error: Invalid discovery type."
                    ;;
                esac
            else
                echo "Error: Port list cannot be empty."
            fi
            ;;
        5)
            clear
            echo "Select ICMP probe type:"
            echo "1. Echo request (-PE)"
            echo "2. Timestamp request (-PP)"
            echo "3. Netmask request (-PM)"
            read -p "Choose an ICMP probe type: " icmp_choice
            case $icmp_choice in
            1)
                # Remove any existing ICMP echo option
                nmap_args=$(echo "$nmap_args" | sed -E 's/-PE//g' | sed 's/  / /g')
                
                nmap_args+=" -PE"
                ping_option_set=true
                echo "Added: -PE"
                ;;
            2)
                # Remove any existing ICMP timestamp option
                nmap_args=$(echo "$nmap_args" | sed -E 's/-PP//g' | sed 's/  / /g')
                
                nmap_args+=" -PP"
                ping_option_set=true
                echo "Added: -PP"
                ;;
            3)
                # Remove any existing ICMP netmask option
                nmap_args=$(echo "$nmap_args" | sed -E 's/-PM//g' | sed 's/  / /g')
                
                nmap_args+=" -PM"
                ping_option_set=true
                echo "Added: -PM"
                ;;
            *)
                echo "Error: Invalid ICMP probe type."
                ;;
            esac
            ;;
        6)
            # Reset all host discovery options
            nmap_args=$(echo "$nmap_args" | sed -E 's/-sL|-sn|-P[nEPM]|-P[SAUY][0-9,]*//g' | sed 's/  / /g')
            ping_option_set=false
            echo "All host discovery options have been reset."
            ;;
        7)
            return_to_menu
            break
            ;;
        "-h"|"--help")
            display_help
            ;;
        *)
            invalid_input
            ;;
        esac
        read -p "Press Enter to continue..."
    done
}


# Scan Techniques Menu
configure_scan_techniques() {
    local scan_technique_set=false
    
    while true; do
        clear
        echo "Scan Techniques Menu:"
        echo "1. TCP SYN Scan (-sS)"
        echo "2. TCP Connect Scan (-sT)"
        echo "3. TCP ACK Scan (-sA)"
        echo "4. TCP Window Scan (-sW)"
        echo "5. TCP Maimon Scan (-sM)"
        echo "6. UDP Scan (-sU)"
        echo "7. TCP Null Scan (-sN)"
        echo "8. TCP FIN Scan (-sF)"
        echo "9. TCP Xmas Scan (-sX)"
        echo "10. Customize TCP Scan Flags (--scanflags)"
        echo "11. Idle Scan (-sI)"
        echo "12. SCTP INIT Scan (-sY)"
        echo "13. SCTP COOKIE-ECHO Scan (-sZ)"
        echo "14. IP Protocol Scan (-sO)"
        echo "15. FTP Bounce Scan (-b)"
        echo "16. Reset scan techniques"
        echo "17. Go back to Main Menu"
        echo
        echo "Current scan techniques: $(filter_nmap_args '-s[ASTWNMUFXIYZVO]|--scanflags|-b')"
        echo
        
        # Check for potential issues
        if [[ "$nmap_args" == *"-sL"* && "$nmap_args" =~ -s[ASTWNMUFXIYZVO] ]]; then
            echo "WARNING: List scan (-sL) with port scanning techniques will only list targets."
            echo "Port scanning will not be performed with -sL option."
            echo
        fi
        
        if [[ "$nmap_args" == *"-sn"* && "$nmap_args" =~ -s[ASTWNMUFXIYZVO] ]]; then
            echo "WARNING: Ping scan (-sn) with port scanning techniques will not scan ports."
            echo "Port scanning will not be performed with -sn option."
            echo
        fi
        
        read -p "Select an option: " choice

        case $choice in
        1)
            # Check for conflicting scan techniques
            check_scan_conflicts "TCP SYN Scan (-sS)" "-sS" "$nmap_args"
            if [ $? -eq 1 ]; then continue; fi
            
            nmap_args+=" -sS"
            scan_technique_set=true
            echo "Added: -sS"
            ;;
        2)
            # Check for conflicting scan techniques
            check_scan_conflicts "TCP Connect Scan (-sT)" "-sT" "$nmap_args"
            if [ $? -eq 1 ]; then continue; fi
            
            nmap_args+=" -sT"
            scan_technique_set=true
            echo "Added: -sT"
            ;;
        3)
            # Check for conflicting scan techniques
            check_scan_conflicts "TCP ACK Scan (-sA)" "-sA" "$nmap_args"
            if [ $? -eq 1 ]; then continue; fi
            
            nmap_args+=" -sA"
            scan_technique_set=true
            echo "Added: -sA"
            ;;
        4)
            # Check for conflicting scan techniques
            check_scan_conflicts "TCP Window Scan (-sW)" "-sW" "$nmap_args"
            if [ $? -eq 1 ]; then continue; fi
            
            nmap_args+=" -sW"
            scan_technique_set=true
            echo "Added: -sW"
            ;;
        5)
            # Check for conflicting scan techniques
            check_scan_conflicts "TCP Maimon Scan (-sM)" "-sM" "$nmap_args"
            if [ $? -eq 1 ]; then continue; fi
            
            nmap_args+=" -sM"
            scan_technique_set=true
            echo "Added: -sM"
            ;;
        6)
            # UDP scan can be combined with a TCP scan technique
            nmap_args+=" -sU"
            scan_technique_set=true
            echo "Added: -sU"
            ;;
        7)
            # Check for conflicting scan techniques
            check_scan_conflicts "TCP Null Scan (-sN)" "-sN" "$nmap_args"
            if [ $? -eq 1 ]; then continue; fi
            
            nmap_args+=" -sN"
            scan_technique_set=true
            echo "Added: -sN"
            ;;
        8)
            # Check for conflicting scan techniques
            check_scan_conflicts "TCP FIN Scan (-sF)" "-sF" "$nmap_args"
            if [ $? -eq 1 ]; then continue; fi
            
            nmap_args+=" -sF"
            scan_technique_set=true
            echo "Added: -sF"
            ;;
        9)
            # Check for conflicting scan techniques
            check_scan_conflicts "TCP Xmas Scan (-sX)" "-sX" "$nmap_args"
            if [ $? -eq 1 ]; then continue; fi
            
            nmap_args+=" -sX"
            scan_technique_set=true
            echo "Added: -sX"
            ;;
        10)
            prompt_input "Enter custom TCP flags (e.g., SYN,ACK,FIN): " flags
            if [[ -n "$flags" ]]; then
                # Check for conflicting scan techniques
                check_scan_conflicts "Custom TCP Flag Scan (--scanflags)" "--scanflags" "$nmap_args"
                if [ $? -eq 1 ]; then continue; fi
                
                nmap_args+=" --scanflags $flags"
                scan_technique_set=true
                echo "Added: --scanflags $flags"
            else
                echo "Error: TCP flags cannot be empty."
            fi
            ;;
        11)
            prompt_input "Enter zombie host (format: host[:probeport]): " zombie
            if [[ -n "$zombie" ]]; then
                # Check for conflicting scan techniques
                check_scan_conflicts "Idle Scan (-sI)" "-sI" "$nmap_args"
                if [ $? -eq 1 ]; then continue; fi
                
                nmap_args+=" -sI $zombie"
                scan_technique_set=true
                echo "Added: -sI $zombie"
            else
                echo "Error: Zombie host cannot be empty."
            fi
            ;;
        12)
            # Check for conflicting scan techniques
            check_scan_conflicts "SCTP INIT Scan (-sY)" "-sY" "$nmap_args"
            if [ $? -eq 1 ]; then continue; fi
            
            nmap_args+=" -sY"
            scan_technique_set=true
            echo "Added: -sY"
            ;;
        13)
            # Check for conflicting scan techniques
            check_scan_conflicts "SCTP COOKIE-ECHO Scan (-sZ)" "-sZ" "$nmap_args"
            if [ $? -eq 1 ]; then continue; fi
            
            nmap_args+=" -sZ"
            scan_technique_set=true
            echo "Added: -sZ"
            ;;
        14)
            # Check for conflicting scan techniques
            check_scan_conflicts "IP Protocol Scan (-sO)" "-sO" "$nmap_args"
            if [ $? -eq 1 ]; then continue; fi
            
            nmap_args+=" -sO"
            scan_technique_set=true
            echo "Added: -sO"
            ;;
        15)
            prompt_input "Enter FTP relay host: " ftp_host
            if [[ -n "$ftp_host" ]]; then
                # Check for conflicting scan techniques
                check_scan_conflicts "FTP Bounce Scan (-b)" "-b" "$nmap_args"
                if [ $? -eq 1 ]; then continue; fi
                
                nmap_args+=" -b $ftp_host"
                scan_technique_set=true
                echo "Added: -b $ftp_host"
            else
                echo "Error: FTP relay host cannot be empty."
            fi
            ;;
        16)
            # Reset all scan technique options
            nmap_args=$(echo "$nmap_args" | sed -E 's/-s[ASTWNMUFXIYZVO][^ ]*//g' | sed -E 's/--scanflags [^ ]+//g' | sed -E 's/-b [^ ]+//g' | sed 's/  / /g')
            scan_technique_set=false
            echo "All scan technique options have been reset."
            ;;
        17)
            return_to_menu
            break
            ;;
        "-h"|"--help")
            display_help
            ;;
        *)
            invalid_input
            ;;
        esac
        read -p "Press Enter to continue..."
    done
}

# Helper function to check for conflicting scan techniques
check_scan_conflicts() {
    local scan_name="$1"
    local scan_option="$2"
    local current_args="$3"
    
    # TCP scan techniques that conflict with each other
    local tcp_scans="-sS -sT -sA -sW -sM -sN -sF -sX --scanflags -sI"
    
    # Check if trying to add a TCP scan when one already exists
    if [[ "$tcp_scans" == *"$scan_option"* ]]; then
        for scan in $tcp_scans; do
            if [[ "$current_args" == *"$scan"* && "$scan" != "$scan_option" ]]; then
                echo "Warning: $scan_name conflicts with existing TCP scan technique."
                echo "Multiple TCP scan techniques cannot be used together."
                read -p "Replace existing TCP scan technique? (y/n): " confirm
                if [[ "$confirm" != "y" ]]; then
                    return 1
                fi
                
                # Remove existing TCP scan techniques
                nmap_args=$(echo "$current_args" | sed -E 's/-s[STAWNMFXI]( [^ ]+)?//g' | sed -E 's/--scanflags [^ ]+//g' | sed 's/  / /g')
                return 0
            fi
        done
    fi
    
    # SCTP scan conflicts
    if [[ "$scan_option" == "-sY" && "$current_args" == *"-sZ"* ]] || [[ "$scan_option" == "-sZ" && "$current_args" == *"-sY"* ]]; then
        echo "Warning: $scan_name conflicts with existing SCTP scan technique."
        echo "Multiple SCTP scan techniques cannot be used together."
        read -p "Replace existing SCTP scan technique? (y/n): " confirm
        if [[ "$confirm" != "y" ]]; then
            return 1
        fi
        
        # Remove existing SCTP scan techniques
        nmap_args=$(echo "$current_args" | sed -E 's/-s[YZ]//g' | sed 's/  / /g')
        return 0
    fi
    
    return 0
}




# Port Specification Menu
configure_port_specification() {
    local port_option_set=false
    
    while true; do
        clear
        echo "Port Specification Menu:"
        echo "1. Scan specific port ranges (-p)"
        echo "2. Exclude specific port ranges (--exclude-ports)"
        echo "3. Fast mode (-F)"
        echo "4. Scan ports sequentially (-r)"
        echo "5. Scan top N most common ports (--top-ports)"
        echo "6. Scan ports more common than a ratio (--port-ratio)"
        echo "7. Reset port options"
        echo "8. Go back to Main Menu"
        echo
        echo "Current port options: $(filter_nmap_args '-p|--exclude-ports|-F|-r|--top-ports|--port-ratio')"
        echo
        
        # Check for conflicts
        if [[ "$nmap_args" == *"-F"* && ("$nmap_args" == *"-p"* || "$nmap_args" == *"--top-ports"* || "$nmap_args" == *"--port-ratio"*) ]]; then
            echo "WARNING: Fast scan (-F) with other port selection options may produce unexpected results."
            echo "Fast scan is already limited to the most common ports."
            echo
        fi
        
        read -p "Select an option: " choice

        case $choice in
        1)
            prompt_input "Enter port ranges (e.g., 22; 1-65535; U:53,111,T:21-25): " ports
            if [[ -n "$ports" ]]; then
                # Check for conflicts with other port selection options
                if [[ "$nmap_args" == *"-F"* || "$nmap_args" == *"--top-ports"* || "$nmap_args" == *"--port-ratio"* ]]; then
                    echo "Warning: Specific port selection conflicts with other port options (-F, --top-ports, --port-ratio)."
                    read -p "Remove conflicting options? (y/n): " confirm
                    if [[ "$confirm" == "y" ]]; then
                        # Remove conflicting options
                        nmap_args=$(echo "$nmap_args" | sed -E 's/-F//g' | sed -E 's/--top-ports [0-9]+//g' | sed -E 's/--port-ratio [0-9.]+//g' | sed 's/  / /g')
                    else
                        echo "Note: Your port selection may be limited by other port options."
                    fi
                fi
                
                # Remove any existing port selection
                nmap_args=$(echo "$nmap_args" | sed -E 's/-p [^ ]+//g' | sed 's/  / /g')
                
                nmap_args+=" -p $ports"
                port_option_set=true
                echo "Added: -p $ports"
            else
                echo "Error: Port ranges cannot be empty."
            fi
            ;;
        2)
            prompt_input "Enter ports to exclude (e.g., 80,443): " exclude_ports
            if [[ -n "$exclude_ports" ]]; then
                # Remove any existing port exclusion
                nmap_args=$(echo "$nmap_args" | sed -E 's/--exclude-ports [^ ]+//g' | sed 's/  / /g')
                
                nmap_args+=" --exclude-ports $exclude_ports"
                echo "Added: --exclude-ports $exclude_ports"
            else
                echo "Error: Excluded ports cannot be empty."
            fi
            ;;
        3)
            # Check for conflicts with other port selection options
            if [[ "$nmap_args" == *"-p"* || "$nmap_args" == *"--top-ports"* || "$nmap_args" == *"--port-ratio"* ]]; then
                echo "Warning: Fast scan (-F) conflicts with other port selection options (-p, --top-ports, --port-ratio)."
                read -p "Continue anyway? (y/n): " confirm
                if [[ "$confirm" != "y" ]]; then
                    continue
                fi
            fi
            
            # Remove any existing fast scan option
            nmap_args=$(echo "$nmap_args" | sed -E 's/-F//g' | sed 's/  / /g')
            
            nmap_args+=" -F"
            port_option_set=true
            echo "Added: -F"
            ;;
        4)
            # Remove any existing sequential scan option
            nmap_args=$(echo "$nmap_args" | sed -E 's/-r//g' | sed 's/  / /g')
            
            nmap_args+=" -r"
            port_option_set=true
            echo "Added: -r"
            ;;
        5)
            prompt_input "Enter number of top ports to scan: " top_ports
            if [[ "$top_ports" =~ ^[0-9]+$ && "$top_ports" -gt 0 ]]; then
                # Check for conflicts with other port selection options
                if [[ "$nmap_args" == *"-F"* || "$nmap_args" == *"-p"* || "$nmap_args" == *"--port-ratio"* ]]; then
                    echo "Warning: Top ports scan conflicts with other port options (-F, -p, --port-ratio)."
                    read -p "Remove conflicting options? (y/n): " confirm
                    if [[ "$confirm" == "y" ]]; then
                        # Remove conflicting options
                        nmap_args=$(echo "$nmap_args" | sed -E 's/-F//g' | sed -E 's/-p [^ ]+//g' | sed -E 's/--port-ratio [0-9.]+//g' | sed 's/  / /g')
                    else
                        echo "Note: Your top ports selection may be limited by other port options."
                    fi
                fi
                
                # Remove any existing top ports option
                nmap_args=$(echo "$nmap_args" | sed -E 's/--top-ports [0-9]+//g' | sed 's/  / /g')
                
                nmap_args+=" --top-ports $top_ports"
                port_option_set=true
                echo "Added: --top-ports $top_ports"
            else
                echo "Error: Number of top ports must be a positive integer."
            fi
            ;;
        6)
            prompt_input "Enter port ratio (0.0-1.0): " port_ratio
            if [[ "$port_ratio" =~ ^[0-9]*\.?[0-9]+$ && $(echo "$port_ratio <= 1.0" | bc -l) -eq 1 && $(echo "$port_ratio > 0.0" | bc -l) -eq 1 ]]; then
                # Check for conflicts with other port selection options
                if [[ "$nmap_args" == *"-F"* || "$nmap_args" == *"-p"* || "$nmap_args" == *"--top-ports"* ]]; then
                    echo "Warning: Port ratio conflicts with other port options (-F, -p, --top-ports)."
                    read -p "Remove conflicting options? (y/n): " confirm
                    if [[ "$confirm" == "y" ]]; then
                        # Remove conflicting options
                        nmap_args=$(echo "$nmap_args" | sed -E 's/-F//g' | sed -E 's/-p [^ ]+//g' | sed -E 's/--top-ports [0-9]+//g' | sed 's/  / /g')
                    else
                        echo "Note: Your port ratio selection may be limited by other port options."
                    fi
                fi
                
                # Remove any existing port ratio option
                nmap_args=$(echo "$nmap_args" | sed -E 's/--port-ratio [0-9.]+//g' | sed 's/  / /g')
                
                nmap_args+=" --port-ratio $port_ratio"
                port_option_set=true
                echo "Added: --port-ratio $port_ratio"
            else
                echo "Error: Port ratio must be a decimal number between 0.0 and 1.0."
            fi
            ;;
        7)
            # Reset all port options
            nmap_args=$(echo "$nmap_args" | sed -E 's/-p [^ ]+//g' | sed -E 's/--exclude-ports [^ ]+//g' | sed -E 's/-F//g' | sed -E 's/-r//g' | sed -E 's/--top-ports [0-9]+//g' | sed -E 's/--port-ratio [0-9.]+//g' | sed 's/  / /g')
            port_option_set=false
            echo "All port options have been reset."
            ;;
        8)
            return_to_menu
            break
            ;;
        "-h"|"--help")
            display_help
            ;;
        *)
            invalid_input
            ;;
        esac
        read -p "Press Enter to continue..."
    done
}



# Fixed Timing and Performance Menu
configure_timing_performance() {
    local timing_template_set=false
    local custom_timing_set=false
    
    while true; do
        clear
        echo "Timing and Performance Menu:"
        echo "1. Set timing template (-T<0-5>)"
        echo "2. Set parallel host scan group sizes (--min-hostgroup/max-hostgroup)"
        echo "3. Adjust probe parallelization (--min-parallelism/max-parallelism)"
        echo "4. Set RTT timeouts (--min-rtt-timeout/max-rtt-timeout/initial-rtt-timeout)"
        echo "5. Cap number of retries (--max-retries)"
        echo "6. Set host timeout (--host-timeout)"
        echo "7. Adjust scan delay (--scan-delay/--max-scan-delay)"
        echo "8. Set minimum packet rate (--min-rate)"
        echo "9. Set maximum packet rate (--max-rate)"
        echo "10. Reset timing options"
        echo "11. Go back to Main Menu"
        echo
        echo "Current timing options: $(filter_nmap_args '-T[0-5]|--min-|--max-|--host-timeout|--scan-delay|--initial-rtt-timeout')"
        echo
        
        if $timing_template_set && $custom_timing_set; then
            echo "WARNING: You have both a timing template (-T) and custom timing options."
            echo "Custom options will override the template settings."
            echo
        fi
        
        read -p "Select an option: " choice

        case $choice in
        1)
            prompt_input "Enter timing template (0-5): " timing
            if [[ "$timing" =~ ^[0-5]$ ]]; then
                if $custom_timing_set; then
                    echo "Warning: Setting a timing template may conflict with custom timing options."
                    echo "Timing templates (-T0 to -T5) set multiple timing parameters automatically."
                    read -p "Continue? (y/n): " confirm
                    if [[ "$confirm" != "y" ]]; then
                        continue
                    fi
                fi
                
                # Remove any existing timing template
                nmap_args=$(echo "$nmap_args" | sed -E 's/-T[0-5]//g' | sed 's/  / /g')
                
                nmap_args+=" -T$timing"
                timing_template_set=true
                echo "Added: -T$timing"
                
                echo -e "\nTiming template information:"
                case $timing in
                    0) echo "T0 (Paranoid): Very slow scan to avoid detection" ;;
                    1) echo "T1 (Sneaky): Slow scan to avoid detection" ;;
                    2) echo "T2 (Polite): Slows down to use less bandwidth and target resources" ;;
                    3) echo "T3 (Normal): Default timing, a balance between accuracy and speed" ;;
                    4) echo "T4 (Aggressive): Faster scans assuming a reasonably fast and reliable network" ;;
                    5) echo "T5 (Insane): Very aggressive timing; prioritizes speed over reliability" ;;
                esac
            else
                echo "Error: Timing template must be a number between 0 and 5."
            fi
            ;;
        2)
            prompt_input "Enter minimum host group size: " min_hostgroup
            prompt_input "Enter maximum host group size: " max_hostgroup
            if [[ "$min_hostgroup" =~ ^[0-9]+$ && "$max_hostgroup" =~ ^[0-9]+$ ]]; then
                if [ "$min_hostgroup" -gt "$max_hostgroup" ]; then
                    echo "Error: Minimum host group size cannot be greater than maximum."
                    continue
                fi
                
                # Remove any existing hostgroup settings
                nmap_args=$(echo "$nmap_args" | sed -E 's/--min-hostgroup [0-9]+//g' | sed -E 's/--max-hostgroup [0-9]+//g' | sed 's/  / /g')
                
                nmap_args+=" --min-hostgroup $min_hostgroup --max-hostgroup $max_hostgroup"
                custom_timing_set=true
                echo "Added: --min-hostgroup $min_hostgroup --max-hostgroup $max_hostgroup"
                
                warn_timing_template_override
            else
                echo "Error: Host group sizes must be positive integers."
            fi
            ;;
        3)
            prompt_input "Enter minimum parallel probes: " min_parallelism
            prompt_input "Enter maximum parallel probes: " max_parallelism
            if [[ "$min_parallelism" =~ ^[0-9]+$ && "$max_parallelism" =~ ^[0-9]+$ ]]; then
                if [ "$min_parallelism" -gt "$max_parallelism" ]; then
                    echo "Error: Minimum parallelism cannot be greater than maximum."
                    continue
                fi
                
                # Remove any existing parallelism settings
                nmap_args=$(echo "$nmap_args" | sed -E 's/--min-parallelism [0-9]+//g' | sed -E 's/--max-parallelism [0-9]+//g' | sed 's/  / /g')
                
                nmap_args+=" --min-parallelism $min_parallelism --max-parallelism $max_parallelism"
                custom_timing_set=true
                echo "Added: --min-parallelism $min_parallelism --max-parallelism $max_parallelism"
                
                warn_timing_template_override
            else
                echo "Error: Parallelism values must be positive integers."
            fi
            ;;
        4)
            prompt_input "Enter initial RTT timeout (e.g., 30ms, 1s): " initial_rtt
            prompt_input "Enter minimum RTT timeout (e.g., 30ms, 1s): " min_rtt
            prompt_input "Enter maximum RTT timeout (e.g., 30ms, 1s): " max_rtt
            
            # Validate format
            if [[ ! "$initial_rtt" =~ ^[0-9]+(ms|s)$ || ! "$min_rtt" =~ ^[0-9]+(ms|s)$ || ! "$max_rtt" =~ ^[0-9]+(ms|s)$ ]]; then
                echo "Error: RTT timeouts must be positive numbers followed by 'ms' or 's' (e.g., 30ms, 1s)."
                continue
            fi
            
            # Convert values to milliseconds for comparison
            local init_ms=$(convert_to_ms "$initial_rtt")
            local min_ms=$(convert_to_ms "$min_rtt")
            local max_ms=$(convert_to_ms "$max_rtt")
            
            if [ $min_ms -gt $max_ms ]; then
                echo "Error: Minimum RTT timeout cannot be greater than maximum RTT timeout."
                continue
            fi
            
            if [ $init_ms -lt $min_ms ]; then
                echo "Warning: Initial RTT timeout is less than minimum RTT timeout."
                echo "This may cause issues. Consider setting initial ≥ minimum."
                read -p "Continue anyway? (y/n): " confirm
                if [[ "$confirm" != "y" ]]; then
                    continue
                fi
            fi
            
            # Remove any existing RTT timeout settings
            nmap_args=$(echo "$nmap_args" | sed -E 's/--initial-rtt-timeout [0-9]+(ms|s)//g' | sed -E 's/--min-rtt-timeout [0-9]+(ms|s)//g' | sed -E 's/--max-rtt-timeout [0-9]+(ms|s)//g' | sed 's/  / /g')
            
            nmap_args+=" --initial-rtt-timeout $initial_rtt --min-rtt-timeout $min_rtt --max-rtt-timeout $max_rtt"
            custom_timing_set=true
            echo "Added: --initial-rtt-timeout $initial_rtt --min-rtt-timeout $min_rtt --max-rtt-timeout $max_rtt"
            
            warn_timing_template_override
            ;;
        5)
            prompt_input "Enter maximum retries: " retries
            if [[ "$retries" =~ ^[0-9]+$ ]]; then
                # Remove any existing max-retries setting
                nmap_args=$(echo "$nmap_args" | sed -E 's/--max-retries [0-9]+//g' | sed 's/  / /g')
                
                nmap_args+=" --max-retries $retries"
                custom_timing_set=true
                echo "Added: --max-retries $retries"
                
                warn_timing_template_override
            else
                echo "Error: Maximum retries must be a positive integer."
            fi
            ;;
        6)
            prompt_input "Enter host timeout (e.g., 30ms, 1s, 5m, 1h): " timeout
            if [[ "$timeout" =~ ^[0-9]+(ms|s|m|h)$ ]]; then
                # Remove any existing host-timeout setting
                nmap_args=$(echo "$nmap_args" | sed -E 's/--host-timeout [0-9]+(ms|s|m|h)//g' | sed 's/  / /g')
                
                nmap_args+=" --host-timeout $timeout"
                custom_timing_set=true
                echo "Added: --host-timeout $timeout"
                
                warn_timing_template_override
            else
                echo "Error: Host timeout must be a positive number followed by 'ms', 's', 'm', or 'h' (e.g., 30ms, 5s, 10m, 1h)."
            fi
            ;;
        7)
            prompt_input "Enter scan delay (e.g., 30ms, 1s): " scan_delay
            prompt_input "Enter maximum scan delay (e.g., 30ms, 1s): " max_scan_delay
            
            # Validate format
            if [[ ! "$scan_delay" =~ ^[0-9]+(ms|s)$ || ! "$max_scan_delay" =~ ^[0-9]+(ms|s)$ ]]; then
                echo "Error: Scan delays must be positive numbers followed by 'ms' or 's' (e.g., 30ms, 1s)."
                continue
            fi
            
            # Convert values to milliseconds for comparison
            local delay_ms=$(convert_to_ms "$scan_delay")
            local max_delay_ms=$(convert_to_ms "$max_scan_delay")
            
            if [ $delay_ms -gt $max_delay_ms ]; then
                echo "Error: Scan delay cannot be greater than maximum scan delay."
                continue
            fi
            
            # Check for conflicts with packet rate options
            if [[ "$nmap_args" == *"--min-rate"* || "$nmap_args" == *"--max-rate"* ]]; then
                echo "Warning: Scan delay options conflict with packet rate options (--min-rate, --max-rate)."
                echo "Using both can produce unpredictable results."
                read -p "Continue anyway? (y/n): " confirm
                if [[ "$confirm" != "y" ]]; then
                    continue
                fi
            fi
            
            # Remove any existing scan delay settings
            nmap_args=$(echo "$nmap_args" | sed -E 's/--scan-delay [0-9]+(ms|s)//g' | sed -E 's/--max-scan-delay [0-9]+(ms|s)//g' | sed 's/  / /g')
            
            nmap_args+=" --scan-delay $scan_delay --max-scan-delay $max_scan_delay"
            custom_timing_set=true
            echo "Added: --scan-delay $scan_delay --max-scan-delay $max_scan_delay"
            
            warn_timing_template_override
            ;;
        8)
            prompt_input "Enter minimum packet rate (packets per second): " min_rate
            if [[ "$min_rate" =~ ^[0-9]+$ ]]; then
                # Check for conflicts with scan delay options
                if [[ "$nmap_args" == *"--scan-delay"* || "$nmap_args" == *"--max-scan-delay"* ]]; then
                    echo "Warning: Packet rate options conflict with scan delay options (--scan-delay, --max-scan-delay)."
                    echo "Using both can produce unpredictable results."
                    read -p "Continue anyway? (y/n): " confirm
                    if [[ "$confirm" != "y" ]]; then
                        continue
                    fi
                fi
                
                # Check for conflict with max-rate
                if [[ "$nmap_args" == *"--max-rate"* ]]; then
                    local max_rate=$(echo "$nmap_args" | grep -oE -- "--max-rate [0-9]+" | awk '{print $2}')
                    if [ "$min_rate" -gt "$max_rate" ]; then
                        echo "Error: Minimum packet rate ($min_rate) cannot be greater than maximum packet rate ($max_rate)."
                        continue
                    fi
                fi
                
                # Remove any existing min-rate setting
                nmap_args=$(echo "$nmap_args" | sed -E 's/--min-rate [0-9]+//g' | sed 's/  / /g')
                
                nmap_args+=" --min-rate $min_rate"
                custom_timing_set=true
                echo "Added: --min-rate $min_rate"
                
                warn_timing_template_override
            else
                echo "Error: Minimum packet rate must be a positive integer."
            fi
            ;;
        9)
            prompt_input "Enter maximum packet rate (packets per second): " max_rate
            if [[ "$max_rate" =~ ^[0-9]+$ ]]; then
                # Check for conflicts with scan delay options
                if [[ "$nmap_args" == *"--scan-delay"* || "$nmap_args" == *"--max-scan-delay"* ]]; then
                    echo "Warning: Packet rate options conflict with scan delay options (--scan-delay, --max-scan-delay)."
                    echo "Using both can produce unpredictable results."
                    read -p "Continue anyway? (y/n): " confirm
                    if [[ "$confirm" != "y" ]]; then
                        continue
                    fi
                fi
                
                # Check for conflict with min-rate
                if [[ "$nmap_args" == *"--min-rate"* ]]; then
                    local min_rate=$(echo "$nmap_args" | grep -oE -- "--min-rate [0-9]+" | awk '{print $2}')
                    if [ "$min_rate" -gt "$max_rate" ]; then
                        echo "Error: Minimum packet rate ($min_rate) cannot be greater than maximum packet rate ($max_rate)."
                        continue
                    fi
                fi
                
                # Remove any existing max-rate setting
                nmap_args=$(echo "$nmap_args" | sed -E 's/--max-rate [0-9]+//g' | sed 's/  / /g')
                
                nmap_args+=" --max-rate $max_rate"
                custom_timing_set=true
                echo "Added: --max-rate $max_rate"
                
                warn_timing_template_override
            else
                echo "Error: Maximum packet rate must be a positive integer."
            fi
            ;;
        10)
            # Reset all timing options
            nmap_args=$(echo "$nmap_args" | sed -E 's/-T[0-5]//g' | 
                sed -E 's/--min-hostgroup [0-9]+//g' | sed -E 's/--max-hostgroup [0-9]+//g' |
                sed -E 's/--min-parallelism [0-9]+//g' | sed -E 's/--max-parallelism [0-9]+//g' |
                sed -E 's/--initial-rtt-timeout [0-9]+(ms|s)//g' | sed -E 's/--min-rtt-timeout [0-9]+(ms|s)//g' | sed -E 's/--max-rtt-timeout [0-9]+(ms|s)//g' |
                sed -E 's/--max-retries [0-9]+//g' |
                sed -E 's/--host-timeout [0-9]+(ms|s|m|h)//g' |
                sed -E 's/--scan-delay [0-9]+(ms|s)//g' | sed -E 's/--max-scan-delay [0-9]+(ms|s)//g' |
                sed -E 's/--min-rate [0-9]+//g' | sed -E 's/--max-rate [0-9]+//g' |
                sed 's/  / /g')
            timing_template_set=false
            custom_timing_set=false
            echo "All timing options have been reset."
            ;;
        11)
            return_to_menu
            break
            ;;
        "-h"|"--help")
            display_help
            ;;
        *)
            invalid_input
            ;;
        esac
        read -p "Press Enter to continue..."
    done
}

# Helper function to convert time values to milliseconds for comparison
convert_to_ms() {
    local time_value="$1"
    local number=$(echo "$time_value" | sed -E 's/[^0-9]//g')
    local unit=$(echo "$time_value" | sed -E 's/[0-9]//g')
    
    if [[ "$unit" == "s" ]]; then
        echo $((number * 1000))
    else
        echo "$number"
    fi
}

# Helper function to warn about timing template override
warn_timing_template_override() {
    if $timing_template_set; then
        echo "Warning: Custom timing options will override settings from timing template (-T)."
    fi
}

# Improved OS Detection Menu
configure_os_detection() {
    local os_detection_enabled=false
    
    while true; do
        clear
        echo "OS Detection Menu:"
        echo "1. Enable OS detection (-O)"
        echo "2. Limit OS detection to promising targets (--osscan-limit)"
        echo "3. Guess OS more aggressively (--osscan-guess)"
        echo "4. Reset OS detection options"
        echo "5. Go back to Main Menu"
        echo
        echo "Current OS detection options: $(filter_nmap_args '-O|--osscan-')"
        echo
        
        # Check if appropriate scan types are configured
        if $os_detection_enabled; then
            check_os_detection_compatibility
        fi
        
        read -p "Select an option: " choice

        case $choice in
        1)
            # Check if port scan is configured
            if ! has_port_scan; then
                echo "Warning: OS detection works best with port scanning enabled."
                echo "For accurate results, OS detection needs at least one open and one closed port."
                echo "Consider adding a port scan option (e.g., -sS, -sT) before enabling OS detection."
                read -p "Enable OS detection anyway? (y/n): " confirm
                if [[ "$confirm" != "y" ]]; then
                    continue
                fi
            fi
            
            nmap_args+=" -O"
            os_detection_enabled=true
            echo "Added: -O"
            ;;
        2)
            if ! $os_detection_enabled; then
                echo "Error: You must enable OS detection first (option 1)."
                continue
            fi
            
            nmap_args+=" --osscan-limit"
            echo "Added: --osscan-limit"
            ;;
        3)
            if ! $os_detection_enabled; then
                echo "Error: You must enable OS detection first (option 1)."
                continue
            fi
            
            nmap_args+=" --osscan-guess"
            echo "Added: --osscan-guess"
            ;;
        4)
            # Reset OS detection options
            nmap_args=$(echo "$nmap_args" | sed -E 's/-O|--osscan-(limit|guess)//g' | sed 's/  / /g')
            os_detection_enabled=false
            echo "All OS detection options have been reset."
            ;;
        5)
            return_to_menu
            break
            ;;
        "-h"|"--help")
            display_help
            ;;
        *)
            invalid_input
            ;;
        esac
        read -p "Press Enter to continue..."
    done
}

# Helper function to check if OS detection will work with current scan configuration
check_os_detection_compatibility() {
    local has_ping=false
    local has_port_scan=false
    
    # Check for ping options
    if [[ "$nmap_args" == *"-P"* || "$nmap_args" != *"-Pn"* ]]; then
        has_ping=true
    fi
    
    # Check for port scan options
    if has_port_scan; then
        has_port_scan=true
    fi
    
    if ! $has_ping && ! $has_port_scan; then
        echo "WARNING: OS detection may fail without host discovery (ping) or port scanning."
        echo "Consider enabling a port scan option (e.g., -sS, -sT) for better results."
        echo
    elif [[ "$nmap_args" == *"-Pn"* ]] && ! $has_port_scan; then
        echo "WARNING: OS detection may fail with ping disabled (-Pn) and no port scan configured."
        echo "Consider enabling a port scan option (e.g., -sS, -sT) for better results."
        echo
    fi
}

# Helper function to check if any port scan options are enabled
has_port_scan() {
    if [[ "$nmap_args" == *"-s"* ]]; then
        return 0  # True
    else
        return 1  # False
    fi
}



# Service/Version Detection Menu - Fixed Version
configure_service_detection() {
    local intensity_set=false
    local version_set=false
    
    while true; do
        clear
        echo "Service/Version Detection Menu:"
        echo "1. Probe open ports to determine service/version info (-sV)"
        echo "2. Set version intensity level (--version-intensity)"
        echo "3. Limit to most likely probes (light scan) (--version-light)"
        echo "4. Try every single probe (intensity 9) (--version-all)"
        echo "5. Show detailed version scan activity (--version-trace)"
        echo "6. Reset version detection options"
        echo "7. Go back to Main Menu"
        echo
        echo "Current detection options: $(filter_nmap_args '-sV|--version-')"
        echo
        read -p "Select an option: " choice

        case $choice in
        1)
            if ! $version_set; then
                nmap_args+=" -sV"
                version_set=true
                echo "Added: -sV"
            else
                echo "Notice: Version detection (-sV) is already enabled."
            fi
            ;;
        2)
            if $intensity_set; then
                echo "Warning: This will override any previous intensity settings (--version-light, --version-all, or --version-intensity)"
                read -p "Continue? (y/n): " confirm
                if [[ "$confirm" != "y" ]]; then
                    continue
                fi
                # Remove any existing intensity options
                nmap_args=$(echo "$nmap_args" | sed -E 's/--version-(light|all|intensity [0-9])//g' | sed 's/  / /g')
            fi
            
            prompt_input "Enter version intensity level (0 to 9): " intensity
            if [[ "$intensity" =~ ^[0-9]$ ]]; then
                nmap_args+=" --version-intensity $intensity"
                intensity_set=true
                echo "Added: --version-intensity $intensity"
            else
                echo "Error: Intensity level must be a number between 0 and 9."
            fi
            ;;
        3)
            if $intensity_set; then
                echo "Warning: This will override any previous intensity settings (--version-intensity or --version-all)"
                read -p "Continue? (y/n): " confirm
                if [[ "$confirm" != "y" ]]; then
                    continue
                fi
                # Remove any existing intensity options
                nmap_args=$(echo "$nmap_args" | sed -E 's/--version-(intensity [0-9]|all)//g' | sed 's/  / /g')
            fi
            
            nmap_args+=" --version-light"
            intensity_set=true
            echo "Added: --version-light (equivalent to --version-intensity 2)"
            ;;
        4)
            if $intensity_set; then
                echo "Warning: This will override any previous intensity settings (--version-intensity or --version-light)"
                read -p "Continue? (y/n): " confirm
                if [[ "$confirm" != "y" ]]; then
                    continue
                fi
                # Remove any existing intensity options
                nmap_args=$(echo "$nmap_args" | sed -E 's/--version-(intensity [0-9]|light)//g' | sed 's/  / /g')
            fi
            
            nmap_args+=" --version-all"
            intensity_set=true
            echo "Added: --version-all (equivalent to --version-intensity 9)"
            ;;
        5)
            nmap_args+=" --version-trace"
            echo "Added: --version-trace"
            ;;
        6)
            # Reset version detection options
            nmap_args=$(echo "$nmap_args" | sed -E 's/-sV|--version-[a-z-]+ ?[0-9]*//g' | sed 's/  / /g')
            version_set=false
            intensity_set=false
            echo "All version detection options have been reset."
            ;;
        7)
            return_to_menu
            break
            ;;
        "-h"|"--help")
            display_help
            ;;
        *)
            invalid_input
            ;;
        esac
        read -p "Press Enter to continue..."
    done
}

# Helper function to filter and display current nmap arguments
filter_nmap_args() {
    local pattern="$1"
    echo "$nmap_args" | grep -oE "$pattern[^ ]*" || echo "None"
}

# ==========================
# SECTION: NSE Script Management
# ==========================

# NSE Script Management Menu
configure_nse_scripts() {
    local script_categories=""
    local custom_scripts=""
    local script_args=""
    
    while true; do
        clear
        echo "🔬 NSE SCRIPT ENGINE MANAGEMENT"
        echo "═══════════════════════════════════════════════════════════════"
        echo "Nmap Scripting Engine (NSE) - Advanced service and vulnerability detection"
        echo
        echo "📚 SCRIPT CATEGORIES:"
        echo "1.  🛡️  Vulnerability Detection   - Find security vulnerabilities"
        echo "2.  🔍 Service Discovery         - Detailed service enumeration"
        echo "3.  🔓 Authentication Testing    - Test weak authentication"
        echo "4.  💥 Brute Force Attacks       - Password and credential testing"
        echo "5.  🌐 Web Application Testing   - HTTP/HTTPS specific tests"
        echo "6.  📧 Mail Server Testing       - SMTP/POP3/IMAP analysis"
        echo "7.  🗃️  Database Testing          - Database service enumeration"
        echo "8.  🔐 SSL/TLS Testing           - Certificate and encryption analysis"
        echo "9.  📂 SMB/NetBIOS Testing       - Windows file sharing analysis"
        echo "10. 🔧 Safe Scripts Only         - Non-intrusive discovery only"
        echo
        echo "🎯 SPECIFIC SCRIPT SELECTION:"
        echo "11. 📝 Add Custom Scripts        - Specify individual scripts"
        echo "12. ⚙️  Configure Script Arguments - Set script-specific parameters"
        echo "13. 📖 Browse Available Scripts  - List all installed NSE scripts"
        echo "14. 🔍 Search Scripts by Keyword - Find scripts for specific purposes"
        echo
        echo "⚙️  MANAGEMENT:"
        echo "15. 📋 View Current Scripts      - Show selected scripts and arguments"
        echo "16. 🗑️  Reset All Scripts        - Clear all script selections"
        echo "17. ⬅️  Back to Main Menu"
        echo
        echo "═══════════════════════════════════════════════════════════════"
        echo "Current scripts: $(get_current_nse_scripts)"
        echo
        read -p "🚀 Select script category or management option: " nse_choice

        case $nse_choice in
        1)
            add_vulnerability_scripts
            ;;
        2)
            add_discovery_scripts
            ;;
        3)
            add_auth_scripts
            ;;
        4)
            add_brute_scripts
            ;;
        5)
            add_web_scripts
            ;;
        6)
            add_mail_scripts
            ;;
        7)
            add_database_scripts
            ;;
        8)
            add_ssl_scripts
            ;;
        9)
            add_smb_scripts
            ;;
        10)
            add_safe_scripts
            ;;
        11)
            add_custom_scripts
            ;;
        12)
            configure_script_arguments
            ;;
        13)
            browse_available_scripts
            ;;
        14)
            search_scripts
            ;;
        15)
            view_current_scripts
            ;;
        16)
            reset_nse_scripts
            ;;
        17)
            return_to_menu
            break
            ;;
        "-h"|"--help")
            display_nse_help
            ;;
        *)
            invalid_input
            ;;
        esac
        read -p "Press Enter to continue..."
    done
}

# NSE Script Category Functions
add_vulnerability_scripts() {
    echo "🛡️ Adding Vulnerability Detection Scripts..."
    nmap_args=$(echo "$nmap_args" | sed -E 's/--script=[^ ]*//g' | sed 's/  / /g')
    nmap_args+=" --script=vuln"
    echo "✅ Added vulnerability detection scripts"
    echo "⚠️  Warning: These scripts may trigger security alerts"
    echo "🎯 Use case: Identify known CVEs and security issues"
}

add_discovery_scripts() {
    echo "🔍 Adding Service Discovery Scripts..."
    nmap_args=$(echo "$nmap_args" | sed -E 's/--script=[^ ]*//g' | sed 's/  / /g')
    nmap_args+=" --script=discovery"
    echo "✅ Added service discovery scripts"
    echo "🎯 Use case: Detailed service enumeration and fingerprinting"
}

add_auth_scripts() {
    echo "🔓 Adding Authentication Testing Scripts..."
    nmap_args=$(echo "$nmap_args" | sed -E 's/--script=[^ ]*//g' | sed 's/  / /g')
    nmap_args+=" --script=auth"
    echo "✅ Added authentication testing scripts"
    echo "⚠️  Warning: May attempt authentication against services"
    echo "🎯 Use case: Test for weak or default authentication"
}

add_brute_scripts() {
    echo "💥 Adding Brute Force Scripts..."
    echo "⚠️  WARNING: Brute force attacks can:"
    echo "   • Lock out user accounts"
    echo "   • Trigger security monitoring"
    echo "   • Be considered malicious activity"
    read -p "Continue with brute force scripts? (y/n): " confirm
    if [[ "$confirm" == "y" ]]; then
        nmap_args=$(echo "$nmap_args" | sed -E 's/--script=[^ ]*//g' | sed 's/  / /g')
        nmap_args+=" --script=brute"
        echo "✅ Added brute force scripts"
        echo "🎯 Use case: Test password strength (use responsibly)"
    else
        echo "❌ Brute force scripts not added"
    fi
}

add_web_scripts() {
    echo "🌐 Adding Web Application Scripts..."
    nmap_args=$(echo "$nmap_args" | sed -E 's/--script=[^ ]*//g' | sed 's/  / /g')
    nmap_args+=" --script=http-*"
    echo "✅ Added web application testing scripts"
    echo "🎯 Use case: HTTP/HTTPS service analysis and testing"
}

add_mail_scripts() {
    echo "📧 Adding Mail Server Scripts..."
    nmap_args=$(echo "$nmap_args" | sed -E 's/--script=[^ ]*//g' | sed 's/  / /g')
    nmap_args+=" --script=smtp-*,pop3-*,imap-*"
    echo "✅ Added mail server testing scripts"
    echo "🎯 Use case: Email service enumeration and configuration analysis"
}

add_database_scripts() {
    echo "🗃️ Adding Database Scripts..."
    nmap_args=$(echo "$nmap_args" | sed -E 's/--script=[^ ]*//g' | sed 's/  / /g')
    nmap_args+=" --script=mysql-*,ms-sql-*,oracle-*,postgres-*"
    echo "✅ Added database testing scripts"
    echo "🎯 Use case: Database service discovery and enumeration"
}

add_ssl_scripts() {
    echo "🔐 Adding SSL/TLS Scripts..."
    nmap_args=$(echo "$nmap_args" | sed -E 's/--script=[^ ]*//g' | sed 's/  / /g')
    nmap_args+=" --script=ssl-*,tls-*"
    echo "✅ Added SSL/TLS testing scripts"
    echo "🎯 Use case: Certificate analysis and encryption testing"
}

add_smb_scripts() {
    echo "📂 Adding SMB/NetBIOS Scripts..."
    nmap_args=$(echo "$nmap_args" | sed -E 's/--script=[^ ]*//g' | sed 's/  / /g')
    nmap_args+=" --script=smb-*,netbios-*"
    echo "✅ Added SMB/NetBIOS testing scripts"
    echo "🎯 Use case: Windows file sharing and network analysis"
}

add_safe_scripts() {
    echo "🔧 Adding Safe Scripts Only..."
    nmap_args=$(echo "$nmap_args" | sed -E 's/--script=[^ ]*//g' | sed 's/  / /g')
    nmap_args+=" --script=safe"
    echo "✅ Added safe, non-intrusive scripts only"
    echo "🎯 Use case: Information gathering without risk"
}

add_custom_scripts() {
    echo "📝 Custom Script Selection"
    echo "════════════════════════════"
    echo "Enter specific NSE scripts separated by commas"
    echo "Examples:"
    echo "  http-title,ssl-cert,ssh-hostkey"
    echo "  ftp-anon,telnet-encryption,dns-zone-transfer"
    echo
    prompt_input "Enter script names: " custom_scripts
    if [[ -n "$custom_scripts" ]]; then
        nmap_args=$(echo "$nmap_args" | sed -E 's/--script=[^ ]*//g' | sed 's/  / /g')
        nmap_args+=" --script=$custom_scripts"
        echo "✅ Added custom scripts: $custom_scripts"
    else
        echo "❌ No scripts specified"
    fi
}

configure_script_arguments() {
    echo "⚙️ Script Arguments Configuration"
    echo "════════════════════════════════════"
    echo "Set arguments for NSE scripts in key=value format"
    echo "Examples:"
    echo "  http.useragent='Mozilla/5.0 Custom'"
    echo "  brute.threads=5,brute.delay=2s"
    echo "  http.max-redirect=3"
    echo
    prompt_input "Enter script arguments: " script_args
    if [[ -n "$script_args" ]]; then
        nmap_args=$(echo "$nmap_args" | sed -E 's/--script-args=[^ ]*//g' | sed 's/  / /g')
        nmap_args+=" --script-args=$script_args"
        echo "✅ Added script arguments: $script_args"
    else
        echo "❌ No arguments specified"
    fi
}

browse_available_scripts() {
    echo "📖 Browsing Available NSE Scripts..."
    echo "═══════════════════════════════════════"
    if command -v locate &> /dev/null; then
        echo "🔍 Found NSE scripts:"
        locate "*.nse" | head -20
        echo "... (showing first 20 results)"
    elif [ -d "/usr/share/nmap/scripts" ]; then
        echo "🔍 NSE scripts in /usr/share/nmap/scripts:"
        ls /usr/share/nmap/scripts/*.nse | head -20
        echo "... (showing first 20 results)"
    else
        echo "❌ Unable to locate NSE scripts directory"
        echo "💡 Try: nmap --script-help all"
    fi
}

search_scripts() {
    echo "🔍 Script Search"
    echo "══════════════════"
    prompt_input "Enter keyword to search for: " keyword
    if [[ -n "$keyword" ]]; then
        echo "🔍 Searching for scripts related to: $keyword"
        nmap --script-help "*$keyword*" 2>/dev/null | head -30
        echo "... (showing first 30 lines)"
    else
        echo "❌ No keyword specified"
    fi
}

view_current_scripts() {
    echo "📋 Current NSE Script Configuration"
    echo "═══════════════════════════════════════"
    local current_scripts=$(get_current_nse_scripts)
    if [[ "$current_scripts" != "None" ]]; then
        echo "Active scripts: $current_scripts"
        
        # Show script arguments if any
        local script_args=$(echo "$nmap_args" | grep -oE -- "--script-args=[^ ]*" || echo "None")
        echo "Script arguments: $script_args"
    else
        echo "❌ No NSE scripts currently configured"
        echo "💡 Use the menu options above to add scripts"
    fi
}

reset_nse_scripts() {
    echo "🗑️ Resetting NSE Scripts..."
    nmap_args=$(echo "$nmap_args" | sed -E 's/--script=[^ ]*//g' | sed -E 's/--script-args=[^ ]*//g' | sed 's/  / /g')
    echo "✅ All NSE scripts and arguments have been reset"
}

get_current_nse_scripts() {
    local scripts=$(echo "$nmap_args" | grep -oE -- "--script=[^ ]*" | sed 's/--script=//')
    if [[ -n "$scripts" ]]; then
        echo "$scripts"
    else
        echo "None"
    fi
}

display_nse_help() {
    clear
    echo "🆘 NSE SCRIPT ENGINE HELP"
    echo "═══════════════════════════════════════════════════════════════"
    echo
    echo "📖 WHAT IS NSE?"
    echo "The Nmap Scripting Engine (NSE) allows you to run custom scripts"
    echo "during scans for advanced service detection, vulnerability assessment,"
    echo "and exploitation. Scripts are written in Lua and cover hundreds"
    echo "of different use cases."
    echo
    echo "🎯 SCRIPT CATEGORIES EXPLAINED:"
    echo
    echo "🛡️  VULNERABILITY (--script=vuln):"
    echo "   • Detects known security vulnerabilities"
    echo "   • Checks for CVEs and security misconfigurations"
    echo "   • Examples: sql-injection, xss-scanner"
    echo
    echo "🔍 DISCOVERY (--script=discovery):"
    echo "   • Gathers detailed service information"
    echo "   • Non-intrusive information collection"
    echo "   • Examples: http-title, ssh-hostkey, dns-zone-transfer"
    echo
    echo "🔓 AUTH (--script=auth):"
    echo "   • Tests authentication mechanisms"
    echo "   • Checks for anonymous access"
    echo "   • Examples: ftp-anon, mysql-empty-password"
    echo
    echo "💥 BRUTE (--script=brute):"
    echo "   • Password and credential attacks"
    echo "   • ⚠️ Can lock accounts - use carefully!"
    echo "   • Examples: ssh-brute, http-brute"
    echo
    echo "🔧 SAFE (--script=safe):"
    echo "   • Non-intrusive scripts only"
    echo "   • Won't crash services or trigger alerts"
    echo "   • Good for production environments"
    echo
    echo "⚙️  SCRIPT ARGUMENTS:"
    echo "Use --script-args to customize script behavior:"
    echo "   • http.useragent='Custom Agent'"
    echo "   • brute.threads=10"
    echo "   • mysql.timeout=5s"
    echo
    echo "💡 BEST PRACTICES:"
    echo "   • Start with 'safe' scripts in production"
    echo "   • Test scripts in lab environments first"
    echo "   • Be aware of script impact and timing"
    echo "   • Some scripts require specific ports to be open"
    echo
    read -p "Press Enter to return to NSE menu..."
}

# Improved Firewall/IDS Evasion Menu
configure_firewall_evasion() {
    # Use global variable to ensure options are saved even if function exits unexpectedly
    EVASION_OPTIONS=${EVASION_OPTIONS:-""}
    
    while true; do
        clear
        echo "Firewall/IDS Evasion Menu:"
        echo "1. Fragment packets (--mtu)"
        echo "2. Cloak scan with decoys (-D)"
        echo "3. Spoof source address (-S)"
        echo "4. Use specified interface (-e)"
        echo "5. Use a specific source port (-g/--source-port)"
        echo "6. Relay connections through proxies (--proxies)"
        echo "7. Append custom payload in hex (--data)"
        echo "8. Append custom ASCII string (--data-string)"
        echo "9. Append random data (--data-length)"
        echo "10. Set IP time-to-live (--ttl)"
        echo "11. Spoof MAC address (--spoof-mac)"
        echo "12. Use bogus checksum (--badsum)"
        echo "13. Reset evasion options"
        echo "14. Go back to Main Menu"
        echo
        echo "Current evasion options: $EVASION_OPTIONS"
        echo
        read -p "Select an option: " choice
        
        case $choice in
        1)
            read -p "Enter MTU size for packet fragmentation (8-1500): " mtu_size
            if [[ "$mtu_size" =~ ^[0-9]+$ ]] && [ "$mtu_size" -ge 8 ] && [ "$mtu_size" -le 1500 ]; then
                # Check if scan type supports fragmentation
                if [[ "$nmap_args" == *"-f"* || "$nmap_args" == *"-sS"* || "$nmap_args" == *"-sT"* || "$nmap_args" == *"-sA"* ]]; then
                    EVASION_OPTIONS="$EVASION_OPTIONS --mtu $mtu_size"
                    echo "Packet fragmentation added with MTU size: $mtu_size"
                else
                    echo "Warning: MTU option works best with -f, -sS, -sT, or -sA scan types."
                    read -p "Add anyway? (y/n): " confirm
                    if [[ "$confirm" == "y" ]]; then
                        EVASION_OPTIONS="$EVASION_OPTIONS --mtu $mtu_size"
                        echo "Packet fragmentation added with MTU size: $mtu_size"
                    fi
                fi
            else
                echo "Invalid MTU size. Must be between 8 and 1500."
            fi
            ;;
        2)
            read -p "Enter decoy IPs (comma-separated, ME for real IP position): " decoys
            if [ -n "$decoys" ]; then
                # Check for conflicts with -S option
                if [[ "$EVASION_OPTIONS" == *"-S "* ]]; then
                    echo "Warning: Decoy scanning (-D) may conflict with source address spoofing (-S)."
                    read -p "Continue anyway? (y/n): " confirm
                    if [[ "$confirm" != "y" ]]; then
                        continue
                    fi
                fi
                EVASION_OPTIONS="$EVASION_OPTIONS -D $decoys"
                echo "Decoy scan added with: $decoys"
            else
                echo "No decoy IPs provided."
            fi
            ;;
        3)
            read -p "Enter IP address to spoof: " spoof_ip
            if [[ "$spoof_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                # Check for decoy conflicts
                if [[ "$EVASION_OPTIONS" == *"-D "* && "$EVASION_OPTIONS" != *"ME"* ]]; then
                    echo "Warning: Source address spoofing (-S) may conflict with decoy scanning (-D)."
                    echo "Consider using 'ME' in your decoy list to specify the position of your real IP."
                    read -p "Continue anyway? (y/n): " confirm
                    if [[ "$confirm" != "y" ]]; then
                        continue
                    fi
                fi
                EVASION_OPTIONS="$EVASION_OPTIONS -S $spoof_ip"
                echo "Source address spoofing added with IP: $spoof_ip"
            else
                echo "Invalid IP address format."
            fi
            ;;
        4)
            read -p "Enter network interface to use: " interface
            if [ -n "$interface" ]; then
                EVASION_OPTIONS="$EVASION_OPTIONS -e $interface"
                echo "Interface set to: $interface"
            else
                echo "No interface provided."
            fi
            ;;
        5)
            read -p "Enter source port number (1-65535): " source_port
            if [[ "$source_port" =~ ^[0-9]+$ ]] && [ "$source_port" -ge 1 ] && [ "$source_port" -le 65535 ]; then
                EVASION_OPTIONS="$EVASION_OPTIONS --source-port $source_port"
                echo "Source port set to: $source_port"
            else
                echo "Invalid port number. Must be between 1 and 65535."
            fi
            ;;
        6)
            read -p "Enter proxy list (comma-separated, format: proto://host:port): " proxies
            if [ -n "$proxies" ]; then
                EVASION_OPTIONS="$EVASION_OPTIONS --proxies $proxies"
                echo "Proxy chain set to: $proxies"
            else
                echo "No proxies provided."
            fi
            ;;
        7)
            read -p "Enter custom payload in hex (e.g., DEADBEEF): " hex_data
            if [[ "$hex_data" =~ ^[0-9A-Fa-f]+$ ]]; then
                # Check for conflicts with other data options
                if [[ "$EVASION_OPTIONS" == *"--data-string"* || "$EVASION_OPTIONS" == *"--data-length"* ]]; then
                    echo "Warning: Only one data option (--data, --data-string, --data-length) can be used at a time."
                    read -p "Replace existing data option? (y/n): " confirm
                    if [[ "$confirm" != "y" ]]; then
                        continue
                    fi
                    # Remove existing data options
                    EVASION_OPTIONS=$(echo "$EVASION_OPTIONS" | sed -E 's/--data(-string|-length)? [^ ]*//g' | sed 's/  / /g')
                fi
                EVASION_OPTIONS="$EVASION_OPTIONS --data 0x$hex_data"
                echo "Custom hex payload added: 0x$hex_data"
            else
                echo "Invalid hex format. Use hexadecimal characters only (0-9, A-F)."
            fi
            ;;
        8)
            read -p "Enter custom ASCII string to append: " ascii_data
            if [ -n "$ascii_data" ]; then
                # Check for conflicts with other data options
                if [[ "$EVASION_OPTIONS" == *"--data 0x"* || "$EVASION_OPTIONS" == *"--data-length"* ]]; then
                    echo "Warning: Only one data option (--data, --data-string, --data-length) can be used at a time."
                    read -p "Replace existing data option? (y/n): " confirm
                    if [[ "$confirm" != "y" ]]; then
                        continue
                    fi
                    # Remove existing data options
                    EVASION_OPTIONS=$(echo "$EVASION_OPTIONS" | sed -E 's/--data(-length)? [^ ]*|--data 0x[^ ]*//g' | sed 's/  / /g')
                fi
                
                # Properly escape the string to prevent command injection
                ascii_data_escaped="${ascii_data//\\/\\\\}"
                ascii_data_escaped="${ascii_data_escaped//\"/\\\"}"
                EVASION_OPTIONS="$EVASION_OPTIONS --data-string \"$ascii_data_escaped\""
                echo "Custom ASCII string added: $ascii_data"
            else
                echo "No ASCII string provided."
            fi
            ;;
        9)
            read -p "Enter length of random data to append (bytes): " data_length
            if [[ "$data_length" =~ ^[0-9]+$ ]] && [ "$data_length" -gt 0 ]; then
                # Check for conflicts with other data options
                if [[ "$EVASION_OPTIONS" == *"--data 0x"* || "$EVASION_OPTIONS" == *"--data-string"* ]]; then
                    echo "Warning: Only one data option (--data, --data-string, --data-length) can be used at a time."
                    read -p "Replace existing data option? (y/n): " confirm
                    if [[ "$confirm" != "y" ]]; then
                        continue
                    fi
                    # Remove existing data options
                    EVASION_OPTIONS=$(echo "$EVASION_OPTIONS" | sed -E 's/--data(-string)? [^ ]*|--data 0x[^ ]*//g' | sed 's/  / /g')
                fi
                EVASION_OPTIONS="$EVASION_OPTIONS --data-length $data_length"
                echo "Random data length set to: $data_length bytes"
            else
                echo "Invalid data length. Must be a positive integer."
            fi
            ;;
        10)
            read -p "Enter TTL value (1-255): " ttl
            if [[ "$ttl" =~ ^[0-9]+$ ]] && [ "$ttl" -ge 1 ] && [ "$ttl" -le 255 ]; then
                EVASION_OPTIONS="$EVASION_OPTIONS --ttl $ttl"
                echo "TTL value set to: $ttl"
            else
                echo "Invalid TTL value. Must be between 1 and 255."
            fi
            ;;
        11)
            echo "MAC address options:"
            echo "  0: Use a random MAC address"
            echo "  vendor: Use a random MAC from that vendor"
            echo "  MAC: Use the specified MAC address"
            read -p "Enter MAC address option: " mac
            if [ -n "$mac" ]; then
                EVASION_OPTIONS="$EVASION_OPTIONS --spoof-mac $mac"
                echo "MAC spoofing set to: $mac"
            else
                echo "No MAC address option provided."
            fi
            ;;
        12)
            EVASION_OPTIONS="$EVASION_OPTIONS --badsum"
            echo "Bogus checksum option added"
            ;;
        13)
            # Reset evasion options
            EVASION_OPTIONS=""
            echo "All evasion options have been reset."
            ;;
        14)
            # Save evasion options to the global configuration before returning
            nmap_args="$nmap_args $EVASION_OPTIONS"
            echo "Firewall/IDS evasion options saved: $EVASION_OPTIONS"
            echo "Returning to Main Menu..."
            return_to_menu
            break
            ;;
        "-h"|"--help")
            display_help
            ;;
        *)
            invalid_input
            ;;
        esac
        read -p "Press Enter to continue..."
    done
}

configure_misc_options() {
    local misc_options=""
    
    while true; do
        clear
        echo "Miscellaneous Options Menu:"
        echo "1. Enable IPv6 scanning (-6)"
        echo "2. Enable OS detection, version detection, script scanning, and traceroute (-A)"
        echo "3. Specify custom Nmap data file location (--datadir)"
        echo "4. Send using raw ethernet frames (--send-eth)"
        echo "5. Send using raw IP packets (--send-ip)"
        echo "6. Assume fully privileged (--privileged)"
        echo "7. Assume unprivileged (--unprivileged)"
        echo "8. Print Nmap version (-V)"
        echo "9. Print help summary (-h)"
        echo "10. Go back to Main Menu"
        echo
        echo "Current miscellaneous options: $misc_options"
        echo
        read -p "Select an option: " choice
        
        case $choice in
        1)
            if [[ "$misc_options" != *"-6"* ]]; then
                misc_options="$misc_options -6"
                echo "IPv6 scanning enabled"
            else
                echo "IPv6 scanning is already enabled"
            fi
            ;;
        2)
            if [[ "$misc_options" != *"-A"* ]]; then
                misc_options="$misc_options -A"
                echo "Aggressive scan enabled (OS detection, version detection, script scanning, and traceroute)"
            else
                echo "Aggressive scan is already enabled"
            fi
            ;;
        3)
            read -p "Enter path to custom Nmap data directory: " datadir
            if [ -d "$datadir" ]; then
                misc_options="$misc_options --datadir \"$datadir\""
                echo "Custom data directory set to: $datadir"
            else
                echo "Warning: Directory '$datadir' does not exist or is not accessible"
                read -p "Use anyway? (y/n): " confirm
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                    misc_options="$misc_options --datadir \"$datadir\""
                    echo "Custom data directory set to: $datadir"
                else
                    echo "Custom data directory not set"
                fi
            fi
            ;;
        4)
            if [[ "$misc_options" == *"--send-ip"* ]]; then
                echo "Warning: --send-ip option is already set. These options are mutually exclusive."
                read -p "Replace with --send-eth? (y/n): " confirm
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                    # Remove --send-ip and add --send-eth
                    misc_options="${misc_options/--send-ip/--send-eth}"
                    echo "Switched to raw ethernet frames (--send-eth)"
                else
                    echo "No changes made"
                fi
            else
                misc_options="$misc_options --send-eth"
                echo "Raw ethernet frames enabled (--send-eth)"
            fi
            ;;
        5)
            if [[ "$misc_options" == *"--send-eth"* ]]; then
                echo "Warning: --send-eth option is already set. These options are mutually exclusive."
                read -p "Replace with --send-ip? (y/n): " confirm
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                    # Remove --send-eth and add --send-ip
                    misc_options="${misc_options/--send-eth/--send-ip}"
                    echo "Switched to raw IP packets (--send-ip)"
                else
                    echo "No changes made"
                fi
            else
                misc_options="$misc_options --send-ip"
                echo "Raw IP packets enabled (--send-ip)"
            fi
            ;;
        6)
            if [[ "$misc_options" == *"--unprivileged"* ]]; then
                echo "Warning: --unprivileged option is already set. These options are mutually exclusive."
                read -p "Replace with --privileged? (y/n): " confirm
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                    # Remove --unprivileged and add --privileged
                    misc_options="${misc_options/--unprivileged/--privileged}"
                    echo "Switched to privileged mode (--privileged)"
                else
                    echo "No changes made"
                fi
            else
                misc_options="$misc_options --privileged"
                echo "Fully privileged mode enabled (--privileged)"
            fi
            ;;
        7)
            if [[ "$misc_options" == *"--privileged"* ]]; then
                echo "Warning: --privileged option is already set. These options are mutually exclusive."
                read -p "Replace with --unprivileged? (y/n): " confirm
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                    # Remove --privileged and add --unprivileged
                    misc_options="${misc_options/--privileged/--unprivileged}"
                    echo "Switched to unprivileged mode (--unprivileged)"
                else
                    echo "No changes made"
                fi
            else
                misc_options="$misc_options --unprivileged"
                echo "Unprivileged mode enabled (--unprivileged)"
            fi
            ;;
        8)
            # This option doesn't get added to the final command - just print Nmap version
            echo "Executing: nmap -V"
            nmap -V
            ;;
        9)
            # This option doesn't get added to the final command - just print help
            echo "Executing: nmap -h"
            nmap -h
            ;;
        10)
            # Save misc options to the global configuration before returning
            SCAN_OPTIONS="$SCAN_OPTIONS $misc_options"
            echo "Miscellaneous options saved: $misc_options"
            echo "Returning to Main Menu..."
            return_to_menu
            break
            ;;
        "-h"|"--help")
            display_help_misc
            ;;
        *)
            invalid_input
            ;;
        esac
        read -p "Press Enter to continue..."
    done
}

# Output Options Menu
configure_output_options() {
    while true; do
        clear
        echo "Output Options Menu:"
        echo "1. Normal output (-oN)"
        echo "2. XML output (-oX)"
        echo "3. Script kiddie output (-oS)"
        echo "4. Grepable output (-oG)"
        echo "5. Output in all formats (-oA)"
        echo "6. Increase verbosity (-v or -vv)"
        echo "7. Enable debugging (-d or -dd)"
        echo "8. Show packet trace (--packet-trace)"
        echo "9. Show reason for port states (--reason)"
        echo "10. Use custom stylesheet (--stylesheet)"
        echo "11. Resume aborted scan (--resume)"
        echo "12. Append output to file (--append-output)"
        echo "13. Disable runtime interaction (--noninteractive)"
        echo "14. Go back to Main Menu"
        read -p "Select an option: " choice

        case $choice in
        1)
            prompt_input "Enter filename for output: " output_file
            if [[ -n "$output_file" ]]; then
                nmap_args+=" -oN $output_file"
                echo "Added: -oN $output_file"
            else
                echo "Error: Filename cannot be empty."
            fi
            ;;
        2)
            prompt_input "Enter filename for output: " output_file
            if [[ -n "$output_file" ]]; then
                nmap_args+=" -oX $output_file"
                echo "Added: -oX $output_file"
            else
                echo "Error: Filename cannot be empty."
            fi
            ;;
        3)
            prompt_input "Enter filename for output: " output_file
            if [[ -n "$output_file" ]]; then
                nmap_args+=" -oS $output_file"
                echo "Added: -oS $output_file"
            else
                echo "Error: Filename cannot be empty."
            fi
            ;;
        4)
            prompt_input "Enter filename for output: " output_file
            if [[ -n "$output_file" ]]; then
                nmap_args+=" -oG $output_file"
                echo "Added: -oG $output_file"
            else
                echo "Error: Filename cannot be empty."
            fi
            ;;
        5)
            prompt_input "Enter base filename for output: " base_file
            if [[ -n "$base_file" ]]; then
                nmap_args+=" -oA $base_file"
                echo "Added: -oA $base_file"
            else
                echo "Error: Base filename cannot be empty."
            fi
            ;;
        6)
            prompt_input "Enter verbosity level (v for normal, vv for more): " verbosity
            if [[ "$verbosity" == "v" || "$verbosity" == "vv" ]]; then
                nmap_args+=" -$verbosity"
                echo "Added: -$verbosity"
            else
                echo "Error: Verbosity level must be 'v' or 'vv'."
            fi
            ;;
        7)
            prompt_input "Enter debugging level (d for normal, dd for more): " debugging
            if [[ "$debugging" == "d" || "$debugging" == "dd" ]]; then
                nmap_args+=" -$debugging"
                echo "Added: -$debugging"
            else
                echo "Error: Debugging level must be 'd' or 'dd'."
            fi
            ;;
        8)
            nmap_args+=" --packet-trace"
            echo "Added: --packet-trace"
            ;;
        9)
            nmap_args+=" --reason"
            echo "Added: --reason"
            ;;
        10)
            prompt_input "Enter stylesheet path/URL: " stylesheet
            if [[ -n "$stylesheet" ]]; then
                nmap_args+=" --stylesheet $stylesheet"
                echo "Added: --stylesheet $stylesheet"
            else
                echo "Error: Stylesheet path/URL cannot be empty."
            fi
            ;;
        11)
            prompt_input "Enter filename to resume from: " resume_file
            if [[ -f "$resume_file" ]]; then
                nmap_args+=" --resume $resume_file"
                echo "Added: --resume $resume_file"
            else
                echo "Error: File '$resume_file' not found!"
            fi
            ;;
        12)
            nmap_args+=" --append-output"
            echo "Added: --append-output"
            ;;
        13)
            nmap_args+=" --noninteractive"
            echo "Added: --noninteractive"
            ;;
        14)
            return_to_menu
            break
            ;;
        "-h"|"--help")
            display_help
            ;;
        *)
            invalid_input
            ;;
        esac
        read -p "Press Enter to continue..."
    done
}

# ==========================
# SECTION: Main Menu
# ==========================

# ==========================
# SECTION: Results Analysis
# ==========================

# Simple results analysis and reporting
analyze_scan_results() {
    while true; do
        clear
        echo "📊 SCAN RESULTS ANALYZER"
        echo "═══════════════════════════════════════════════════════════════"
        echo
        echo "📄 ANALYSIS OPTIONS:"
        echo "1.  📋 Quick Summary          - Parse and summarize recent scan results"
        echo "2.  🔍 Detailed Analysis      - In-depth examination of scan output"
        echo "3.  📈 Generate Report        - Create formatted reports (HTML/CSV)"
        echo "4.  🎯 Find Live Hosts        - Extract and list discovered hosts"
        echo "5.  🔌 Open Ports Summary     - List all open ports found"
        echo "6.  🔬 Service Enumeration    - Extract service and version info"
        echo "7.  🛡️  Security Assessment   - Highlight potential security issues"
        echo "8.  📊 Statistics Overview    - Scan statistics and metrics"
        echo "9.  ⬅️  Back to Main Menu"
        echo
        echo "═══════════════════════════════════════════════════════════════"
        read -p "📊 Select analysis option: " analysis_choice

        case $analysis_choice in
        1)
            quick_results_summary
            ;;
        2)
            detailed_results_analysis
            ;;
        3)
            generate_custom_report
            ;;
        4)
            extract_live_hosts
            ;;
        5)
            summarize_open_ports
            ;;
        6)
            extract_service_info
            ;;
        7)
            security_assessment
            ;;
        8)
            scan_statistics
            ;;
        9)
            return_to_menu
            break
            ;;
        "-h"|"--help")
            display_analysis_help
            ;;
        *)
            invalid_input
            ;;
        esac
        read -p "Press Enter to continue..."
    done
}

quick_results_summary() {
    echo "📋 Quick Results Summary"
    echo "═══════════════════════════════"
    prompt_input "Enter path to Nmap output file (XML/normal): " results_file
    
    if [[ ! -f "$results_file" ]]; then
        echo "❌ File not found: $results_file"
        return
    fi
    
    echo "🔍 Analyzing: $results_file"
    echo
    
    # Count hosts
    if grep -q "Nmap scan report for" "$results_file"; then
        local host_count=$(grep -c "Nmap scan report for" "$results_file")
        echo "🖥️  Hosts scanned: $host_count"
    fi
    
    # Count open ports
    if grep -q "open" "$results_file"; then
        local open_ports=$(grep -c "/tcp.*open\|/udp.*open" "$results_file")
        echo "🔌 Open ports found: $open_ports"
    fi
    
    # Find common services
    echo "🔬 Common services detected:"
    grep -o "[0-9]*/tcp.*open.*" "$results_file" | head -10 | while read line; do
        echo "   $line"
    done
}

detailed_results_analysis() {
    echo "🔍 Detailed Results Analysis"
    echo "═══════════════════════════════════"
    echo "Feature coming soon: Advanced parsing and analysis"
    echo "Will include vulnerability mapping, service correlation, etc."
}

generate_custom_report() {
    echo "📈 Generate Custom Report"
    echo "═══════════════════════════════"
    echo "Feature coming soon: Export to HTML, PDF, CSV formats"
    echo "Will include executive summaries and technical details"
}

extract_live_hosts() {
    echo "🎯 Live Hosts Extraction"
    echo "═══════════════════════════════"
    prompt_input "Enter path to Nmap output file: " results_file
    
    if [[ ! -f "$results_file" ]]; then
        echo "❌ File not found: $results_file"
        return
    fi
    
    echo "🔍 Extracting live hosts from: $results_file"
    echo
    echo "📋 Live Hosts Found:"
    grep "Nmap scan report for" "$results_file" | sed 's/Nmap scan report for //' | while read host; do
        echo "   ✅ $host"
    done
}

summarize_open_ports() {
    echo "🔌 Open Ports Summary"
    echo "═══════════════════════════"
    prompt_input "Enter path to Nmap output file: " results_file
    
    if [[ ! -f "$results_file" ]]; then
        echo "❌ File not found: $results_file"
        return
    fi
    
    echo "🔍 Analyzing open ports in: $results_file"
    echo
    echo "📋 Open Ports by Service:"
    grep -E "[0-9]+/(tcp|udp).*open" "$results_file" | sort | uniq -c | sort -nr
}

extract_service_info() {
    echo "🔬 Service Information Extraction"
    echo "═══════════════════════════════════════"
    echo "Feature coming soon: Detailed service enumeration"
    echo "Will extract versions, banners, and service details"
}

security_assessment() {
    echo "🛡️ Security Assessment"
    echo "═══════════════════════════"
    echo "Feature coming soon: Automated security analysis"
    echo "Will highlight potential vulnerabilities and misconfigurations"
}

scan_statistics() {
    echo "📊 Scan Statistics"
    echo "════════════════════"
    prompt_input "Enter path to Nmap output file: " results_file
    
    if [[ ! -f "$results_file" ]]; then
        echo "❌ File not found: $results_file"
        return
    fi
    
    echo "📈 Statistics for: $results_file"
    echo
    
    # File size
    local file_size=$(ls -lh "$results_file" | awk '{print $5}')
    echo "📄 File size: $file_size"
    
    # Scan duration
    if grep -q "Nmap done" "$results_file"; then
        local scan_time=$(grep "Nmap done" "$results_file" | grep -o "in [0-9.]* seconds" || echo "Unknown")
        echo "⏱️  Scan duration: $scan_time"
    fi
    
    # Line count
    local line_count=$(wc -l < "$results_file")
    echo "📝 Total lines: $line_count"
}

display_analysis_help() {
    clear
    echo "🆘 RESULTS ANALYSIS HELP"
    echo "═══════════════════════════════════════════════════════════════"
    echo
    echo "📖 ABOUT RESULTS ANALYSIS:"
    echo "The Results Analyzer helps you parse and understand Nmap scan output."
    echo "It can process both normal text output and XML formatted results."
    echo
    echo "📄 SUPPORTED FILE FORMATS:"
    echo "• Normal output (-oN): Human-readable text format"
    echo "• XML output (-oX): Structured XML for automated processing"
    echo "• Grepable output (-oG): Easy to parse with grep/awk"
    echo
    echo "🔍 ANALYSIS FEATURES:"
    echo "• Host discovery summary"
    echo "• Open port enumeration" 
    echo "• Service identification"
    echo "• Security assessment (coming soon)"
    echo "• Custom reporting (coming soon)"
    echo
    echo "💡 TIPS:"
    echo "• Use XML output for best analysis results"
    echo "• Combine with -oA for all output formats"
    echo "• Save scan results in organized directories"
    echo
    read -p "Press Enter to return to analysis menu..."
}

# ==========================
# SECTION: Main Menu
# ==========================

main() {
    # Check for help flag on script invocation
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        display_help
    fi

    check_nmap_installed
    display_banner

    while true; do
        clear
        echo "🎯 NMAP ARCHITECT - MAIN MENU"
        echo "═══════════════════════════════════════════════════════════════"
        echo
        echo "🚀 QUICK START:"
        echo "1.  📋 Scan Templates             - Pre-configured scan setups"
        echo "2.  🎯 Target Specification       - Define scan targets"
        echo
        echo "🔍 DISCOVERY & SCANNING:"
        echo "3.  📡 Host Discovery             - Find live hosts"
        echo "4.  🔓 Scan Techniques            - Choose scanning methods"
        echo "5.  🔌 Port Specification         - Configure port ranges"
        echo "6.  🔬 Service/Version Detection  - Identify services"
        echo "7.  🖥️  OS Detection              - Operating system fingerprinting"
        echo
        echo "🔬 ADVANCED ANALYSIS:"
        echo "8.  🧪 NSE Script Engine          - Advanced scripts & vulnerability detection"
        echo "9.  ⏱️  Timing and Performance     - Speed and stealth options"
        echo "10. 🛡️  Firewall/IDS Evasion      - Bypass security controls"
        echo
        echo "⚙️  CONFIGURATION & OUTPUT:"
        echo "11. 🔧 Miscellaneous Options      - Additional settings"
        echo "12. 📄 Output Configuration       - Results and reporting"
        echo "13. 📊 Analyze Scan Results       - Parse and analyze previous scans"
        echo
        echo "📊 COMMAND MANAGEMENT:"
        echo "14. 👁️  View Current Command       - Show built command"
        echo "15. 📋 Show Active Options        - Display all configured options"
        echo "16. 🗑️  Reset Command             - Clear all settings"
        echo
        echo "🚀 EXECUTION:"
        echo "17. ▶️  Run Nmap Scan             - Execute the configured scan"
        echo "18. ❌ Exit                       - Close Nmap Architect"
        echo
        echo "═══════════════════════════════════════════════════════════════"
        echo "💡 Type '-h' or '--help' for help • 🎯 Start with Templates for quick setup"
        read -p "🚀 Select your mission: " main_choice

        case $main_choice in
        1)
            configure_scan_templates
            ;;
        2)
            configure_target_specification
            ;;
        3)
            configure_host_discovery
            ;;
        4)
            configure_scan_techniques
            ;;
        5)
            configure_port_specification
            ;;
        6)
            configure_service_detection
            ;;
        7)
            configure_os_detection
            ;;
        8)
            configure_nse_scripts
            ;;
        9)
            configure_timing_performance
            ;;
        10)
            configure_firewall_evasion
            ;;
        11)
            configure_misc_options
            ;;
        12)
            configure_output_options
            ;;
        12)
            configure_output_options
            ;;
        13)
            analyze_scan_results
            ;;
        14)
            if [[ -z "$nmap_args" ]]; then
            echo "No options selected yet."
            else
                echo "Current Nmap Command: nmap $nmap_args"
                check_sudo
            fi
            read -p "Press Enter to continue..."
            ;;
        15)
            show_active_options
            ;;    
        16)
            nmap_args=""
            echo "Command reset successfully."
            read -p "Press Enter to continue..."
            ;;
        17)
            if [[ -z "$nmap_args" ]]; then
                echo "Error: No options selected. Please configure the scan first."
            else
                # Check if target is already specified in the command
                if [[ ! "$nmap_args" =~ -iL|--iL|-iR|--iR|[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ ]]; then
                    prompt_input "Enter target (IP, hostname, or network): " target
                    if [[ -n "$target" ]]; then
                        final_command="nmap $nmap_args $target"
                    else
                        echo "Error: Target cannot be empty."
                        read -p "Press Enter to continue..."
                        continue
                    fi
                else
                    final_command="nmap $nmap_args"
                fi
                
                echo "Running: $final_command"
                
                # Check if sudo is needed
                if [[ "$nmap_args" =~ -sS|-sU|-sY|-sZ|-sO|-sA|-sW|-sM|-sN|-sF|-sX|--scanflags|-O|--osscan ]]; then
                    echo "This scan requires root privileges. Running with sudo..."
                    sudo $final_command
                else
                    eval $final_command
                fi
            fi
            read -p "Press Enter to continue..."
            ;;
        18)
            echo "🚀 Thank you for using Nmap Architect!"
            echo "🛡️  Happy hunting and stay ethical! 🛡️"
            exit 0
            ;;
        "-h"|"--help")
            display_help
            ;;
        "tips"|"tip")
            show_tips
            ;;
        *)
            invalid_input
            ;;
        esac
    done
}

# Start the script
main "$@"
