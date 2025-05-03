
#!/bin/bash

# Global variable to accumulate Nmap arguments
nmap_args=""

# ==========================
# SECTION: Utility Functions
# ==========================

# Function to display help information
display_help() {
    clear
    echo "---------------------------------------------------------"
    echo "Nmap Architect - Advanced Nmap Command Builder"
    echo "---------------------------------------------------------"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -h, --help    Display this help menu and exit"
    echo
    echo "Description:"
    echo "  Nmap Architect is an interactive tool to build and execute complex Nmap commands."
    echo "  Select options from various categories to construct your scan, then run it with ease."
    echo
    echo "Main Menu Options:"
    echo "  1. Target Specification      - Set targets (e.g., IP, file, random hosts)"
    echo "  2. Host Discovery           - Configure host discovery methods"
    echo "  3. Scan Techniques         - Choose scan types (e.g., -sS, -sT, -sU)"
    echo "  4. Port Specification      - Define port ranges and scan order"
    echo "  5. Service/Version Detection - Detect services and versions on ports"
    echo "  6. OS Detection            - Identify operating systems"
    echo "  7. Timing and Performance  - Optimize scan timing and performance"
    echo "  8. Firewall/IDS Evasion    - Configure evasion techniques"
    echo "  9. Miscellaneous Options   - Additional Nmap options"
    echo " 10. Output Configuration    - Set output formats and verbosity"
    echo " 11. View Current Command    - Display the constructed Nmap command"
    echo " 12. Reset Command          - Clear all selected options"
    echo " 13. Run Nmap Scan         - Execute the built command"
    echo " 14. Exit                  - Quit the tool"
    echo
    echo "Examples:"
    echo "  1. Run the tool: $0"
    echo "  2. View help:    $0 --help"
    echo "  3. Build a command like: nmap -sS -iL targets.txt"
    echo
    echo "Note: Ensure Nmap is installed before running the tool."
    echo "---------------------------------------------------------"
    exit 0
}

# Function to display introduction banner
display_banner() {
    clear
    echo "====================================="
    echo "    |\ | ._ _   _. ._   /\  ._ _     "
    echo "    | \| | | | (_| |_) /--\ | (_     "
    echo "                   |                 "
    echo "====================================="
    echo "    Welcome to Nmap Architect"
    echo "    Build Nmap Scans Like a Pro"
    echo "====================================="
    echo "Type '-h' or '--help' at any time for usage info."
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
# SECTION: Configuration Menus
# ==========================

# Target Specification Menu
configure_target_specification() {
    while true; do
        clear
        echo "Target Specification Menu:"
        echo "1. Input from list of hosts/networks (-iL)"
        echo "2. Choose random targets (-iR)"
        echo "3. Exclude hosts/networks (--exclude)"
        echo "4. Exclude list from file (--excludefile)"
        echo "5. Go back to Main Menu"
        read -p "Select an option: " choice

        case $choice in
        1)
            prompt_input "Enter filename containing target hosts/networks: " filename
            if [[ -f "$filename" ]]; then
                nmap_args+=" -iL $filename"
                echo "Added: -iL $filename"
            else
                echo "Error: File '$filename' not found!"
            fi
            ;;
        2)
            prompt_input "Enter the number of random hosts to scan: " num_hosts
            if [[ "$num_hosts" =~ ^[0-9]+$ && "$num_hosts" -gt 0 ]]; then
                nmap_args+=" -iR $num_hosts"
                echo "Added: -iR $num_hosts"
            else
                echo "Error: Number of hosts must be a positive integer."
            fi
            ;;
        3)
            prompt_input "Enter hosts/networks to exclude (comma-separated): " exclude_list
            if [[ -n "$exclude_list" ]]; then
                nmap_args+=" --exclude $exclude_list"
                echo "Added: --exclude $exclude_list"
            else
                echo "Error: Exclude list cannot be empty."
            fi
            ;;
        4)
            prompt_input "Enter filename containing exclude list: " exclude_file
            if [[ -f "$exclude_file" ]]; then
                nmap_args+=" --excludefile $exclude_file"
                echo "Added: --excludefile $exclude_file"
            else
                echo "Error: File '$exclude_file' not found!"
            fi
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


# Host Discovery Menu
configure_host_discovery() {
    while true; do
        clear
        echo "Host Discovery Menu:"
        echo "1. List Scan (-sL)"
        echo "2. Ping Scan (-sn)"
        echo "3. Treat all hosts as online (-Pn)"
        echo "4. TCP SYN/ACK, UDP, or SCTP discovery to given ports (-PS/PA/PU/PY)"
        echo "5. ICMP echo, timestamp, and netmask request probes (-PE/PP/PM)"
        echo "6. Go back to Main Menu"
        read -p "Select an option: " choice

        case $choice in
        1)
            nmap_args+=" -sL"
            echo "Added: -sL"
            ;;
        2)
            nmap_args+=" -sn"
            echo "Added: -sn"
            ;;
        3)
            nmap_args+=" -Pn"
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
                    nmap_args+=" -PS$ports"
                    echo "Added: -PS$ports"
                    ;;
                2)
                    nmap_args+=" -PA$ports"
                    echo "Added: -PA$ports"
                    ;;
                3)
                    nmap_args+=" -PU$ports"
                    echo "Added: -PU$ports"
                    ;;
                4)
                    nmap_args+=" -PY$ports"
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
                nmap_args+=" -PE"
                echo "Added: -PE"
                ;;
            2)
                nmap_args+=" -PP"
                echo "Added: -PP"
                ;;
            3)
                nmap_args+=" -PM"
                echo "Added: -PM"
                ;;
            *)
                echo "Error: Invalid ICMP probe type."
                ;;
            esac
            ;;
        6)
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
        echo "16. Go back to Main Menu"
        read -p "Select an option: " choice

        case $choice in
        1)
            nmap_args+=" -sS"
            echo "Added: -sS"
            ;;
        2)
            nmap_args+=" -sT"
            echo "Added: -sT"
            ;;
        3)
            nmap_args+=" -sA"
            echo "Added: -sA"
            ;;
        4)
            nmap_args+=" -sW"
            echo "Added: -sW"
            ;;
        5)
            nmap_args+=" -sM"
            echo "Added: -sM"
            ;;
        6)
            nmap_args+=" -sU"
            echo "Added: -sU"
            ;;
        7)
            nmap_args+=" -sN"
            echo "Added: -sN"
            ;;
        8)
            nmap_args+=" -sF"
            echo "Added: -sF"
            ;;
        9)
            nmap_args+=" -sX"
            echo "Added: -sX"
            ;;
        10)
            prompt_input "Enter custom TCP flags (e.g., SYN,ACK,FIN): " flags
            if [[ -n "$flags" ]]; then
                nmap_args+=" --scanflags $flags"
                echo "Added: --scanflags $flags"
            else
                echo "Error: TCP flags cannot be empty."
            fi
            ;;
        11)
            prompt_input "Enter zombie host (format: host[:probeport]): " zombie
            if [[ -n "$zombie" ]]; then
                nmap_args+=" -sI $zombie"
                echo "Added: -sI $zombie"
            else
                echo "Error: Zombie host cannot be empty."
            fi
            ;;
        12)
            nmap_args+=" -sY"
            echo "Added: -sY"
            ;;
        13)
            nmap_args+=" -sZ"
            echo "Added: -sZ"
            ;;
        14)
            nmap_args+=" -sO"
            echo "Added: -sO"
            ;;
        15)
            prompt_input "Enter FTP relay host: " ftp_host
            if [[ -n "$ftp_host" ]]; then
                nmap_args+=" -b $ftp_host"
                echo "Added: -b $ftp_host"
            else
                echo "Error: FTP relay host cannot be empty."
            fi
            ;;
        16)
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


# Port Specification Menu
configure_port_specification() {
    while true; do
        clear
        echo "Port Specification Menu:"
        echo "1. Scan specific port ranges (-p)"
        echo "2. Exclude specific port ranges (--exclude-ports)"
        echo "3. Fast mode (-F)"
        echo "4. Scan ports sequentially (-r)"
        echo "5. Scan top N most common ports (--top-ports)"
        echo "6. Scan ports more common than a ratio (--port-ratio)"
        echo "7. Go back to Main Menu"
        read -p "Select an option: " choice

        case $choice in
        1)
            prompt_input "Enter port ranges (e.g., 22; 1-65535; U:53,111,T:21-25): " ports
            if [[ -n "$ports" ]]; then
                nmap_args+=" -p $ports"
                echo "Added: -p $ports"
            else
                echo "Error: Port ranges cannot be empty."
            fi
            ;;
        2)
            prompt_input "Enter ports to exclude (e.g., 80,443): " exclude_ports
            if [[ -n "$exclude_ports" ]]; then
                nmap_args+=" --exclude-ports $exclude_ports"
                echo "Added: --exclude-ports $exclude_ports"
            else
                echo "Error: Excluded ports cannot be empty."
            fi
            ;;
        3)
            nmap_args+=" -F"
            echo "Added: -F"
            ;;
        4)
            nmap_args+=" -r"
            echo "Added: -r"
            ;;
        5)
            prompt_input "Enter number of top ports to scan: " top_ports
            if [[ "$top_ports" =~ ^[0-9]+$ && "$top_ports" -gt 0 && "$top_ports" -le 65535 ]]; then
                nmap_args+=" --top-ports $top_ports"
                echo "Added: --top-ports $top_ports"
            else
                echo "Error: Number of top ports must be a positive integer between 1 and 65535."
            fi
            ;;
        6)
            prompt_input "Enter port ratio (0.0 to 1.0): " ratio
            if [[ "$ratio" =~ ^0\.[0-9]+$ || "$ratio" == "1.0" || "$ratio" == "0.0" ]]; then
                nmap_args+=" --port-ratio $ratio"
                echo "Added: --port-ratio $ratio"
            else
                echo "Error: Port ratio must be a decimal between 0.0 and 1.0."
            fi
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



# Service/Version Detection Menu

configure_service_detection() {
    while true; do
        clear
        echo "Service/Version Detection Menu:"
        echo "1. Probe open ports to determine service/version info (-sV)"
        echo "2. Set version intensity level (--version-intensity)"
        echo "3. Limit to most likely probes (light scan) (--version-light)"
        echo "4. Try every single probe (intensity 9) (--version-all)"
        echo "5. Show detailed version scan activity (--version-trace)"
        echo "6. Go back to Main Menu"
        read -p "Select an option: " choice

        case $choice in
        1)
            nmap_args+=" -sV"
            echo "Added: -sV"
            ;;
        2)
            prompt_input "Enter version intensity level (0 to 9): " intensity
            if [[ "$intensity" =~ ^[0-9]$ ]]; then
                nmap_args+=" --version-intensity $intensity"
                echo "Added: --version-intensity $intensity"
            else
                echo "Error: Intensity level must be a number between 0 and 9."
            fi
            ;;
        3)
            nmap_args+=" --version-light"
            echo "Added: --version-light"
            ;;
        4)
            nmap_args+=" --version-all"
            echo "Added: --version-all"
            ;;
        5)
            nmap_args+=" --version-trace"
            echo "Added: --version-trace"
            ;;
        6)
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

# OS Detection Menu
configure_os_detection() {
    while true; do
        clear
        echo "OS Detection Menu:"
        echo "1. Enable OS detection (-O)"
        echo "2. Limit OS detection to promising targets (--osscan-limit)"
        echo "3. Guess OS more aggressively (--osscan-guess)"
        echo "4. Go back to Main Menu"
        read -p "Select an option: " choice

        case $choice in
        1)
            nmap_args+=" -O"
            echo "Added: -O"
            ;;
        2)
            nmap_args+=" --osscan-limit"
            echo "Added: --osscan-limit"
            ;;
        3)
            nmap_args+=" --osscan-guess"
            echo "Added: --osscan-guess"
            ;;
        4)
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


# Timing and Performance Menu
configure_timing_performance() {
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
        echo "10. Go back to Main Menu"
        read -p "Select an option: " choice

        case $choice in
        1)
            prompt_input "Enter timing template (0-5): " timing
            if [[ "$timing" =~ ^[0-5]$ ]]; then
                nmap_args+=" -T$timing"
                echo "Added: -T$timing"
            else
                echo "Error: Timing template must be a number between 0 and 5."
            fi
            ;;
        2)
            prompt_input "Enter minimum host group size: " min_hostgroup
            prompt_input "Enter maximum host group size: " max_hostgroup
            if [[ "$min_hostgroup" =~ ^[0-9]+$ && "$max_hostgroup" =~ ^[0-9]+$ && "$min_hostgroup" -le "$max_hostgroup" ]]; then
                nmap_args+=" --min-hostgroup $min_hostgroup --max-hostgroup $max_hostgroup"
                echo "Added: --min-hostgroup $min_hostgroup --max-hostgroup $max_hostgroup"
            else
                echo "Error: Host group sizes must be positive integers, and minimum must not exceed maximum."
            fi
            ;;
        3)
            prompt_input "Enter minimum parallel probes: " min_parallelism
            prompt_input "Enter maximum parallel probes: " max_parallelism
            if [[ "$min_parallelism" =~ ^[0-9]+$ && "$max_parallelism" =~ ^[0-9]+$ && "$min_parallelism" -le "$max_parallelism" ]]; then
                nmap_args+=" --min-parallelism $min_parallelism --max-parallelism $max_parallelism"
                echo "Added: --min-parallelism $min_parallelism --max-parallelism $max_parallelism"
            else
                echo "Error: Parallelism values must be positive integers, and minimum must not exceed maximum."
            fi
            ;;
        4)
            prompt_input "Enter initial RTT timeout (e.g., 30ms, 1s): " initial_rtt
            prompt_input "Enter minimum RTT timeout (e.g., 30ms, 1s): " min_rtt
            prompt_input "Enter maximum RTT timeout (e.g., 30ms, 1s): " max_rtt
            if [[ "$initial_rtt" =~ ^[0-9]+(ms|s)$ && "$min_rtt" =~ ^[0-9]+(ms|s)$ && "$max_rtt" =~ ^[0-9]+(ms|s)$ ]]; then
                nmap_args+=" --initial-rtt-timeout $initial_rtt --min-rtt-timeout $min_rtt --max-rtt-timeout $max_rtt"
                echo "Added: --initial-rtt-timeout $initial_rtt --min-rtt-timeout $min_rtt --max-rtt-timeout $max_rtt"
            else
                echo "Error: RTT timeouts must be positive numbers followed by 'ms' or 's' (e.g., 30ms, 1s)."
            fi
            ;;
        5)
            prompt_input "Enter maximum retries: " retries
            if [[ "$retries" =~ ^[0-9]+$ ]]; then
                nmap_args+=" --max-retries $retries"
                echo "Added: --max-retries $retries"
            else
                echo "Error: Maximum retries must be a positive integer."
            fi
            ;;
        6)
            prompt_input "Enter host timeout (e.g., 30ms, 1s): " timeout
            if [[ "$timeout" =~ ^[0-9]+(ms|s)$ ]]; then
                nmap_args+=" --host-timeout $timeout"
                echo "Added: --host-timeout $timeout"
            else
                echo "Error: Host timeout must be a positive number followed by 'ms' or 's' (e.g., 30ms, 1s)."
            fi
            ;;
        7)
            prompt_input "Enter scan delay (e.g., 30ms, 1s): " scan_delay
            prompt_input "Enter maximum scan delay (e.g., 30ms, 1s): " max_scan_delay
            if [[ "$scan_delay" =~ ^[0-9]+(ms|s)$ && "$max_scan_delay" =~ ^[0-9]+(ms|s)$ ]]; then
                nmap_args+=" --scan-delay $scan_delay --max-scan-delay $max_scan_delay"
                echo "Added: --scan-delay $scan_delay --max-scan-delay $max_scan_delay"
            else
                echo "Error: Scan delays must be positive numbers followed by 'ms' or 's' (e.g., 30ms, 1s)."
            fi
            ;;
        8)
            prompt_input "Enter minimum packet rate: " min_rate
            if [[ "$min_rate" =~ ^[0-9]+$ ]]; then
                nmap_args+=" --min-rate $min_rate"
                echo "Added: --min-rate $min_rate"
            else
                echo "Error: Minimum packet rate must be a positive integer."
            fi
            ;;
        9)
            prompt_input "Enter maximum packet rate: " max_rate
            if [[ "$max_rate" =~ ^[0-9]+$ ]]; then
                nmap_args+=" --max-rate $max_rate"
                echo "Added: --max-rate $max_rate"
            else
                echo "Error: Maximum packet rate must be a positive integer."
            fi
            ;;
        10)
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


# Firewall/IDS Evasion Menu
configure_firewall_evasion() {
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
        echo "10. Send packets with specific IP options (--ip-options)"
        echo "11. Set IP time-to-live (--ttl)"
        echo "12. Spoof MAC address (--spoof-mac)"
        echo "13. Use bogus checksum (--badsum)"
        echo "14. Go back to Main Menu"
        read -p "Select an option: " choice

        case $choice in
        1) ;;
        2) ;;
        3) ;;
        4) ;;
        5) ;;
        6) ;;
        7) ;;
        8) ;;
        9) ;;
        10) ;;
        11) ;;
        12) ;;
        13) ;;
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

# Miscellaneous Options Menu
configure_misc_options() {
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
        read -p "Select an option: " choice

        case $choice in
        1) ;;
        2) ;;
        3) ;;
        4) ;;
        5) ;;
        6) ;;
        7) ;;
        8) ;;
        9) ;;
        10)
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

main() {
    # Check for help flag on script invocation
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        display_help
    fi

    check_nmap_installed
    display_banner

    while true; do
        clear
        echo "MAIN MENU:"
        echo "1. Target Specification"
        echo "2. Host Discovery"
        echo "3. Scan Techniques"
        echo "4. Port Specification"
        echo "5. Service/Version Detection"
        echo "6. OS Detection"
        echo "7. Timing and Performance"
        echo "8. Firewall/IDS Evasion"
        echo "9. Miscellaneous Options"
        echo "10. Output Configuration"
        echo "11. View Current Command"
        echo "12. Reset Command"
        echo "13. Run Nmap Scan"
        echo "14. Exit"
        read -p "Select an option: " main_choice

        case $main_choice in
        1)
            configure_target_specification
            ;;
        2)
            configure_host_discovery
            ;;
        3)
            configure_scan_techniques
            ;;
        4)
            configure_port_specification
            ;;
        5)
            configure_service_detection
            ;;
        6)
            configure_os_detection
            ;;
        7)
            configure_timing_performance
            ;;
        8)
            configure_firewall_evasion
            ;;
        9)
            configure_misc_options
            ;;
        10)
            configure_output_options
            ;;
        11)
            if [[ -z "$nmap_args" ]]; then
                echo "No options selected yet."
            else
                echo "Current Nmap Command: nmap $nmap_args"
            fi
            read -p "Press Enter to continue..."
            ;;
        12)
            nmap_args=""
            echo "Command reset successfully."
            read -p "Press Enter to continue..."
            ;;
        13)
            if [[ -z "$nmap_args" ]]; then
                echo "Error: No options selected. Please configure the scan first."
            else
                if [[ ! "$nmap_args" =~ -iL|-iR ]]; then
                    prompt_input "Enter target (IP, hostname, or network): " target
                    if [[ -n "$target" ]]; then
                        nmap_args+=" $target"
                    else
                        echo "Error: Target cannot be empty."
                        read -p "Press Enter to continue..."
                        continue
                    fi
                fi
                echo "Running: nmap $nmap_args"
                nmap $nmap_args
                nmap_args=""
            fi
            read -p "Press Enter to continue..."
            ;;
        14)
            echo "Exiting Nmap Architect. Goodbye!"
            exit 0
            ;;
        "-h"|"--help")
            display_help
            ;;
        *)
            invalid_input
            ;;
        esac
    done
}

# Start the script
main "$@"
