
#!/bin/bash

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
    echo " 12. View Active Options      - Show currently selected options"
    echo " 13. Reset Command          - Clear all selected options"
    echo " 14. Run Nmap Scan         - Execute the built command"
    echo " 15. Exit                  - Quit the tool"
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
    echo "    |\ | ._ *   *. ._   /\  ._ _     "
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
# configure_target_specification() {
#     while true; do
#         clear
#         echo "Target Specification Menu:"
#         echo "1. Input single IP/hostname"
#         echo "2. Input from list of hosts/networks (-iL)"
#         echo "3. Choose random targets (-iR)"
#         echo "4. Exclude hosts/networks (--exclude)"
#         echo "5. Exclude list from file (--excludefile)"
#         echo "6. Go back to Main Menu"
#         read -p "Select an option: " choice
#         case $choice in
#         1)
#             prompt_input "Enter target IP address or hostname: " target
#             if [[ -n "$target" ]]; then
#                 nmap_args+=" $target"
#                 echo "Added target: $target"
#             else
#                 echo "Error: Target cannot be empty."
#             fi
#             ;;
#         2)
#             prompt_input "Enter filename containing target hosts/networks: " filename
#             if [[ -f "$filename" ]]; then
#                 nmap_args+=" -iL $filename"
#                 echo "Added: -iL $filename"
#             else
#                 echo "Error: File '$filename' not found!"
#                 echo "Note: If the file is in the same directory as this script, simply use the filename (e.g., 'targets.txt')."
#             fi
#             ;;
#         3)
#             prompt_input "Enter the number of random hosts to scan: " num_hosts
#             if [[ "$num_hosts" =~ ^[0-9]+$ && "$num_hosts" -gt 0 ]]; then
#                 nmap_args+=" -iR $num_hosts"
#                 echo "Added: -iR $num_hosts"
#             else
#                 echo "Error: Number of hosts must be a positive integer."
#             fi
#             ;;
#         4)
#             prompt_input "Enter hosts/networks to exclude (comma-separated): " exclude_list
#             if [[ -n "$exclude_list" ]]; then
#                 nmap_args+=" --exclude $exclude_list"
#                 echo "Added: --exclude $exclude_list"
#             else
#                 echo "Error: Exclude list cannot be empty."
#             fi
#             ;;
#         5)
#             prompt_input "Enter filename containing exclude list: " exclude_file
#             if [[ -f "$exclude_file" ]]; then
#                 nmap_args+=" --excludefile $exclude_file"
#                 echo "Added: --excludefile $exclude_file"
#             else
#                 echo "Error: File '$exclude_file' not found!"
#                 echo "Note: If the file is in the same directory as this script, simply use the filename (e.g., 'excludes.txt')."
#             fi
#             ;;
#         6)
#             return_to_menu
#             break
#             ;;
#         "-h"|"--help")
#             display_help
#             ;;
#         *)
#             invalid_input
#             ;;
#         esac
#         read -p "Press Enter to continue..."
#     done
# }


# Host Discovery Menu
# configure_host_discovery() {
#     while true; do
#         clear
#         echo "Host Discovery Menu:"
#         echo "1. List Scan (-sL)"
#         echo "2. Ping Scan (-sn)"
#         echo "3. Treat all hosts as online (-Pn)"
#         echo "4. TCP SYN/ACK, UDP, or SCTP discovery to given ports (-PS/PA/PU/PY)"
#         echo "5. ICMP echo, timestamp, and netmask request probes (-PE/PP/PM)"
#         echo "6. Go back to Main Menu"
#         read -p "Select an option: " choice

#         case $choice in
#         1)
#             nmap_args+=" -sL"
#             echo "Added: -sL"
#             ;;
#         2)
#             nmap_args+=" -sn"
#             echo "Added: -sn"
#             ;;
#         3)
#             nmap_args+=" -Pn"
#             echo "Added: -Pn"
#             ;;
#         4)
#             prompt_input "Enter port list for discovery (e.g., 22,80,443): " ports
#             if [[ -n "$ports" ]]; then
#                 clear
#                 echo "Select discovery type for ports: $ports"
#                 echo "1. TCP SYN (-PS)"
#                 echo "2. TCP ACK (-PA)"
#                 echo "3. UDP (-PU)"
#                 echo "4. SCTP (-PY)"
#                 read -p "Choose a discovery type: " type_choice
#                 case $type_choice in
#                 1)
#                     nmap_args+=" -PS$ports"
#                     echo "Added: -PS$ports"
#                     ;;
#                 2)
#                     nmap_args+=" -PA$ports"
#                     echo "Added: -PA$ports"
#                     ;;
#                 3)
#                     nmap_args+=" -PU$ports"
#                     echo "Added: -PU$ports"
#                     ;;
#                 4)
#                     nmap_args+=" -PY$ports"
#                     echo "Added: -PY$ports"
#                     ;;
#                 *)
#                     echo "Error: Invalid discovery type."
#                     ;;
#                 esac
#             else
#                 echo "Error: Port list cannot be empty."
#             fi
#             ;;
#         5)
#             clear
#             echo "Select ICMP probe type:"
#             echo "1. Echo request (-PE)"
#             echo "2. Timestamp request (-PP)"
#             echo "3. Netmask request (-PM)"
#             read -p "Choose an ICMP probe type: " icmp_choice
#             case $icmp_choice in
#             1)
#                 nmap_args+=" -PE"
#                 echo "Added: -PE"
#                 ;;
#             2)
#                 nmap_args+=" -PP"
#                 echo "Added: -PP"
#                 ;;
#             3)
#                 nmap_args+=" -PM"
#                 echo "Added: -PM"
#                 ;;
#             *)
#                 echo "Error: Invalid ICMP probe type."
#                 ;;
#             esac
#             ;;
#         6)
#             return_to_menu
#             break
#             ;;
#         "-h"|"--help")
#             display_help
#             ;;
#         *)
#             invalid_input
#             ;;
#         esac
#         read -p "Press Enter to continue..."
#     done
# }


# Scan Techniques Menu
# configure_scan_techniques() {
#     while true; do
#         clear
#         echo "Scan Techniques Menu:"
#         echo "1. TCP SYN Scan (-sS)"
#         echo "2. TCP Connect Scan (-sT)"
#         echo "3. TCP ACK Scan (-sA)"
#         echo "4. TCP Window Scan (-sW)"
#         echo "5. TCP Maimon Scan (-sM)"
#         echo "6. UDP Scan (-sU)"
#         echo "7. TCP Null Scan (-sN)"
#         echo "8. TCP FIN Scan (-sF)"
#         echo "9. TCP Xmas Scan (-sX)"
#         echo "10. Customize TCP Scan Flags (--scanflags)"
#         echo "11. Idle Scan (-sI)"
#         echo "12. SCTP INIT Scan (-sY)"
#         echo "13. SCTP COOKIE-ECHO Scan (-sZ)"
#         echo "14. IP Protocol Scan (-sO)"
#         echo "15. FTP Bounce Scan (-b)"
#         echo "16. Go back to Main Menu"
#         read -p "Select an option: " choice

#         case $choice in
#         1)
#             nmap_args+=" -sS"
#             echo "Added: -sS"
#             ;;
#         2)
#             nmap_args+=" -sT"
#             echo "Added: -sT"
#             ;;
#         3)
#             nmap_args+=" -sA"
#             echo "Added: -sA"
#             ;;
#         4)
#             nmap_args+=" -sW"
#             echo "Added: -sW"
#             ;;
#         5)
#             nmap_args+=" -sM"
#             echo "Added: -sM"
#             ;;
#         6)
#             nmap_args+=" -sU"
#             echo "Added: -sU"
#             ;;
#         7)
#             nmap_args+=" -sN"
#             echo "Added: -sN"
#             ;;
#         8)
#             nmap_args+=" -sF"
#             echo "Added: -sF"
#             ;;
#         9)
#             nmap_args+=" -sX"
#             echo "Added: -sX"
#             ;;
#         10)
#             prompt_input "Enter custom TCP flags (e.g., SYN,ACK,FIN): " flags
#             if [[ -n "$flags" ]]; then
#                 nmap_args+=" --scanflags $flags"
#                 echo "Added: --scanflags $flags"
#             else
#                 echo "Error: TCP flags cannot be empty."
#             fi
#             ;;
#         11)
#             prompt_input "Enter zombie host (format: host[:probeport]): " zombie
#             if [[ -n "$zombie" ]]; then
#                 nmap_args+=" -sI $zombie"
#                 echo "Added: -sI $zombie"
#             else
#                 echo "Error: Zombie host cannot be empty."
#             fi
#             ;;
#         12)
#             nmap_args+=" -sY"
#             echo "Added: -sY"
#             ;;
#         13)
#             nmap_args+=" -sZ"
#             echo "Added: -sZ"
#             ;;
#         14)
#             nmap_args+=" -sO"
#             echo "Added: -sO"
#             ;;
#         15)
#             prompt_input "Enter FTP relay host: " ftp_host
#             if [[ -n "$ftp_host" ]]; then
#                 nmap_args+=" -b $ftp_host"
#                 echo "Added: -b $ftp_host"
#             else
#                 echo "Error: FTP relay host cannot be empty."
#             fi
#             ;;
#         16)
#             return_to_menu
#             break
#             ;;
#         "-h"|"--help")
#             display_help
#             ;;
#         *)
#             invalid_input
#             ;;
#         esac
#         read -p "Press Enter to continue..."
#     done
# }
# Target Specification Menu
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
                }
                
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
                }
                
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
                }
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
# configure_port_specification() {
#     while true; do
#         clear
#         echo "Port Specification Menu:"
#         echo "1. Scan specific port ranges (-p)"
#         echo "2. Exclude specific port ranges (--exclude-ports)"
#         echo "3. Fast mode (-F)"
#         echo "4. Scan ports sequentially (-r)"
#         echo "5. Scan top N most common ports (--top-ports)"
#         echo "6. Scan ports more common than a ratio (--port-ratio)"
#         echo "7. Go back to Main Menu"
#         read -p "Select an option: " choice

#         case $choice in
#         1)
#             prompt_input "Enter port ranges (e.g., 22; 1-65535; U:53,111,T:21-25): " ports
#             if [[ -n "$ports" ]]; then
#                 nmap_args+=" -p $ports"
#                 echo "Added: -p $ports"
#             else
#                 echo "Error: Port ranges cannot be empty."
#             fi
#             ;;
#         2)
#             prompt_input "Enter ports to exclude (e.g., 80,443): " exclude_ports
#             if [[ -n "$exclude_ports" ]]; then
#                 nmap_args+=" --exclude-ports $exclude_ports"
#                 echo "Added: --exclude-ports $exclude_ports"
#             else
#                 echo "Error: Excluded ports cannot be empty."
#             fi
#             ;;
#         3)
#             nmap_args+=" -F"
#             echo "Added: -F"
#             ;;
#         4)
#             nmap_args+=" -r"
#             echo "Added: -r"
#             ;;
#         5)
#             prompt_input "Enter number of top ports to scan: " top_ports
#             if [[ "$top_ports" =~ ^[0-9]+$ && "$top_ports" -gt 0 && "$top_ports" -le 65535 ]]; then
#                 nmap_args+=" --top-ports $top_ports"
#                 echo "Added: --top-ports $top_ports"
#             else
#                 echo "Error: Number of top ports must be a positive integer between 1 and 65535."
#             fi
#             ;;
#         6)
#             prompt_input "Enter port ratio (0.0 to 1.0): " ratio
#             if [[ "$ratio" =~ ^0\.[0-9]+$ || "$ratio" == "1.0" || "$ratio" == "0.0" ]]; then
#                 nmap_args+=" --port-ratio $ratio"
#                 echo "Added: --port-ratio $ratio"
#             else
#                 echo "Error: Port ratio must be a decimal between 0.0 and 1.0."
#             fi
#             ;;
#         7)
#             return_to_menu
#             break
#             ;;
#         "-h"|"--help")
#             display_help
#             ;;
#         *)
#             invalid_input
#             ;;
#         esac
#         read -p "Press Enter to continue..."
#     done
# }
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

# # Service/Version Detection Menu
# configure_service_detection() {
#     while true; do
#         clear
#         echo "Service/Version Detection Menu:"
#         echo "1. Probe open ports to determine service/version info (-sV)"
#         echo "2. Set version intensity level (--version-intensity)"
#         echo "3. Limit to most likely probes (light scan) (--version-light)"
#         echo "4. Try every single probe (intensity 9) (--version-all)"
#         echo "5. Show detailed version scan activity (--version-trace)"
#         echo "6. Go back to Main Menu"
#         read -p "Select an option: " choice

#         case $choice in
#         1)
#             nmap_args+=" -sV"
#             echo "Added: -sV"
#             ;;
#         2)
#             prompt_input "Enter version intensity level (0 to 9): " intensity
#             if [[ "$intensity" =~ ^[0-9]$ ]]; then
#                 nmap_args+=" --version-intensity $intensity"
#                 echo "Added: --version-intensity $intensity"
#             else
#                 echo "Error: Intensity level must be a number between 0 and 9."
#             fi
#             ;;
#         3)
#             nmap_args+=" --version-light"
#             echo "Added: --version-light"
#             ;;
#         4)
#             nmap_args+=" --version-all"
#             echo "Added: --version-all"
#             ;;
#         5)
#             nmap_args+=" --version-trace"
#             echo "Added: --version-trace"
#             ;;
#         6)
#             return_to_menu
#             break
#             ;;
#         "-h"|"--help")
#             display_help
#             ;;
#         *)
#             invalid_input
#             ;;
#         esac
#         read -p "Press Enter to continue..."
#     done
# }

# # OS Detection Menu
# configure_os_detection() {
#     while true; do
#         clear
#         echo "OS Detection Menu:"
#         echo "1. Enable OS detection (-O)"
#         echo "2. Limit OS detection to promising targets (--osscan-limit)"
#         echo "3. Guess OS more aggressively (--osscan-guess)"
#         echo "4. Go back to Main Menu"
#         read -p "Select an option: " choice

#         case $choice in
#         1)
#             nmap_args+=" -O"
#             echo "Added: -O"
#             ;;
#         2)
#             nmap_args+=" --osscan-limit"
#             echo "Added: --osscan-limit"
#             ;;
#         3)
#             nmap_args+=" --osscan-guess"
#             echo "Added: --osscan-guess"
#             ;;
#         4)
#             return_to_menu
#             break
#             ;;
#         "-h"|"--help")
#             display_help
#             ;;
#         *)
#             invalid_input
#             ;;
#         esac
#         read -p "Press Enter to continue..."
#     done
# }

# # Timing and Performance Menu
# configure_timing_performance() {
#     while true; do
#         clear
#         echo "Timing and Performance Menu:"
#         echo "1. Set timing template (-T<0-5>)"
#         echo "2. Set parallel host scan group sizes (--min-hostgroup/max-hostgroup)"
#         echo "3. Adjust probe parallelization (--min-parallelism/max-parallelism)"
#         echo "4. Set RTT timeouts (--min-rtt-timeout/max-rtt-timeout/initial-rtt-timeout)"
#         echo "5. Cap number of retries (--max-retries)"
#         echo "6. Set host timeout (--host-timeout)"
#         echo "7. Adjust scan delay (--scan-delay/--max-scan-delay)"
#         echo "8. Set minimum packet rate (--min-rate)"
#         echo "9. Set maximum packet rate (--max-rate)"
#         echo "10. Go back to Main Menu"
#         read -p "Select an option: " choice

#         case $choice in
#         1)
#             prompt_input "Enter timing template (0-5): " timing
#             if [[ "$timing" =~ ^[0-5]$ ]]; then
#                 nmap_args+=" -T$timing"
#                 echo "Added: -T$timing"
#             else
#                 echo "Error: Timing template must be a number between 0 and 5."
#             fi
#             ;;
#         2)
#             prompt_input "Enter minimum host group size: " min_hostgroup
#             prompt_input "Enter maximum host group size: " max_hostgroup
#             if [[ "$min_hostgroup" =~ ^[0-9]+$ && "$max_hostgroup" =~ ^[0-9]+$ && "$min_hostgroup" -le "$max_hostgroup" ]]; then
#                 nmap_args+=" --min-hostgroup $min_hostgroup --max-hostgroup $max_hostgroup"
#                 echo "Added: --min-hostgroup $min_hostgroup --max-hostgroup $max_hostgroup"
#             else
#                 echo "Error: Host group sizes must be positive integers, and minimum must not exceed maximum."
#             fi
#             ;;
#         3)
#             prompt_input "Enter minimum parallel probes: " min_parallelism
#             prompt_input "Enter maximum parallel probes: " max_parallelism
#             if [[ "$min_parallelism" =~ ^[0-9]+$ && "$max_parallelism" =~ ^[0-9]+$ && "$min_parallelism" -le "$max_parallelism" ]]; then
#                 nmap_args+=" --min-parallelism $min_parallelism --max-parallelism $max_parallelism"
#                 echo "Added: --min-parallelism $min_parallelism --max-parallelism $max_parallelism"
#             else
#                 echo "Error: Parallelism values must be positive integers, and minimum must not exceed maximum."
#             fi
#             ;;
#         4)
#             prompt_input "Enter initial RTT timeout (e.g., 30ms, 1s): " initial_rtt
#             prompt_input "Enter minimum RTT timeout (e.g., 30ms, 1s): " min_rtt
#             prompt_input "Enter maximum RTT timeout (e.g., 30ms, 1s): " max_rtt
#             if [[ "$initial_rtt" =~ ^[0-9]+(ms|s)$ && "$min_rtt" =~ ^[0-9]+(ms|s)$ && "$max_rtt" =~ ^[0-9]+(ms|s)$ ]]; then
#                 nmap_args+=" --initial-rtt-timeout $initial_rtt --min-rtt-timeout $min_rtt --max-rtt-timeout $max_rtt"
#                 echo "Added: --initial-rtt-timeout $initial_rtt --min-rtt-timeout $min_rtt --max-rtt-timeout $max_rtt"
#             else
#                 echo "Error: RTT timeouts must be positive numbers followed by 'ms' or 's' (e.g., 30ms, 1s)."
#             fi
#             ;;
#         5)
#             prompt_input "Enter maximum retries: " retries
#             if [[ "$retries" =~ ^[0-9]+$ ]]; then
#                 nmap_args+=" --max-retries $retries"
#                 echo "Added: --max-retries $retries"
#             else
#                 echo "Error: Maximum retries must be a positive integer."
#             fi
#             ;;
#         6)
#             prompt_input "Enter host timeout (e.g., 30ms, 1s): " timeout
#             if [[ "$timeout" =~ ^[0-9]+(ms|s)$ ]]; then
#                 nmap_args+=" --host-timeout $timeout"
#                 echo "Added: --host-timeout $timeout"
#             else
#                 echo "Error: Host timeout must be a positive number followed by 'ms' or 's' (e.g., 30ms, 1s)."
#             fi
#             ;;
#         7)
#             prompt_input "Enter scan delay (e.g., 30ms, 1s): " scan_delay
#             prompt_input "Enter maximum scan delay (e.g., 30ms, 1s): " max_scan_delay
#             if [[ "$scan_delay" =~ ^[0-9]+(ms|s)$ && "$max_scan_delay" =~ ^[0-9]+(ms|s)$ ]]; then
#                 nmap_args+=" --scan-delay $scan_delay --max-scan-delay $max_scan_delay"
#                 echo "Added: --scan-delay $scan_delay --max-scan-delay $max_scan_delay"
#             else
#                 echo "Error: Scan delays must be positive numbers followed by 'ms' or 's' (e.g., 30ms, 1s)."
#             fi
#             ;;
#         8)
#             prompt_input "Enter minimum packet rate: " min_rate
#             if [[ "$min_rate" =~ ^[0-9]+$ ]]; then
#                 nmap_args+=" --min-rate $min_rate"
#                 echo "Added: --min-rate $min_rate"
#             else
#                 echo "Error: Minimum packet rate must be a positive integer."
#             fi
#             ;;
#         9)
#             prompt_input "Enter maximum packet rate: " max_rate
#             if [[ "$max_rate" =~ ^[0-9]+$ ]]; then
#                 nmap_args+=" --max-rate $max_rate"
#                 echo "Added: --max-rate $max_rate"
#             else
#                 echo "Error: Maximum packet rate must be a positive integer."
#             fi
#             ;;
#         10)
#             return_to_menu
#             break
#             ;;
#         "-h"|"--help")
#             display_help
#             ;;
#         *)
#             invalid_input
#             ;;
#         esac
#         read -p "Press Enter to continue..."
#     done
# }

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

# configure_firewall_evasion() {
#     local evasion_options=""
    
#     while true; do
#         clear
#         echo "Firewall/IDS Evasion Menu:"
#         echo "1. Fragment packets (--mtu)"
#         echo "2. Cloak scan with decoys (-D)"
#         echo "3. Spoof source address (-S)"
#         echo "4. Use specified interface (-e)"
#         echo "5. Use a specific source port (-g/--source-port)"
#         echo "6. Relay connections through proxies (--proxies)"
#         echo "7. Append custom payload in hex (--data)"
#         echo "8. Append custom ASCII string (--data-string)"
#         echo "9. Append random data (--data-length)"
#         echo "10. Send packets with specific IP options (--ip-options)"
#         echo "11. Set IP time-to-live (--ttl)"
#         echo "12. Spoof MAC address (--spoof-mac)"
#         echo "13. Use bogus checksum (--badsum)"
#         echo "14. Go back to Main Menu"
#         echo
#         echo "Current evasion options: $evasion_options"
#         echo
#         read -p "Select an option: " choice
        
#         case $choice in
#         1)
#             read -p "Enter MTU size for packet fragmentation (8-1500): " mtu_size
#             if [[ "$mtu_size" =~ ^[0-9]+$ ]] && [ "$mtu_size" -ge 8 ] && [ "$mtu_size" -le 1500 ]; then
#                 evasion_options="$evasion_options --mtu $mtu_size"
#                 echo "Packet fragmentation added with MTU size: $mtu_size"
#             else
#                 echo "Invalid MTU size. Must be between 8 and 1500."
#             fi
#             ;;
#         2)
#             read -p "Enter decoy IPs (comma-separated, ME for real IP position): " decoys
#             if [ -n "$decoys" ]; then
#                 evasion_options="$evasion_options -D $decoys"
#                 echo "Decoy scan added with: $decoys"
#             else
#                 echo "No decoy IPs provided."
#             fi
#             ;;
#         3)
#             read -p "Enter IP address to spoof: " spoof_ip
#             if [[ "$spoof_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
#                 evasion_options="$evasion_options -S $spoof_ip"
#                 echo "Source address spoofing added with IP: $spoof_ip"
#             else
#                 echo "Invalid IP address format."
#             fi
#             ;;
#         4)
#             read -p "Enter network interface to use: " interface
#             if [ -n "$interface" ]; then
#                 evasion_options="$evasion_options -e $interface"
#                 echo "Interface set to: $interface"
#             else
#                 echo "No interface provided."
#             fi
#             ;;
#         5)
#             read -p "Enter source port number (1-65535): " source_port
#             if [[ "$source_port" =~ ^[0-9]+$ ]] && [ "$source_port" -ge 1 ] && [ "$source_port" -le 65535 ]; then
#                 evasion_options="$evasion_options --source-port $source_port"
#                 echo "Source port set to: $source_port"
#             else
#                 echo "Invalid port number. Must be between 1 and 65535."
#             fi
#             ;;
#         6)
#             read -p "Enter proxy list (comma-separated, format: proto://host:port): " proxies
#             if [ -n "$proxies" ]; then
#                 evasion_options="$evasion_options --proxies $proxies"
#                 echo "Proxy chain set to: $proxies"
#             else
#                 echo "No proxies provided."
#             fi
#             ;;
#         7)
#             read -p "Enter custom payload in hex (e.g., DEADBEEF): " hex_data
#             if [[ "$hex_data" =~ ^[0-9A-Fa-f]+$ ]]; then
#                 evasion_options="$evasion_options --data 0x$hex_data"
#                 echo "Custom hex payload added: 0x$hex_data"
#             else
#                 echo "Invalid hex format. Use hexadecimal characters only (0-9, A-F)."
#             fi
#             ;;
#         8)
#             read -p "Enter custom ASCII string to append: " ascii_data
#             if [ -n "$ascii_data" ]; then
#                 # Escape the string for command line use
#                 ascii_data_escaped=$(printf '%q' "$ascii_data")
#                 evasion_options="$evasion_options --data-string $ascii_data_escaped"
#                 echo "Custom ASCII string added: $ascii_data"
#             else
#                 echo "No ASCII string provided."
#             fi
#             ;;
#         9)
#             read -p "Enter length of random data to append (bytes): " data_length
#             if [[ "$data_length" =~ ^[0-9]+$ ]] && [ "$data_length" -gt 0 ]; then
#                 evasion_options="$evasion_options --data-length $data_length"
#                 echo "Random data length set to: $data_length bytes"
#             else
#                 echo "Invalid data length. Must be a positive integer."
#             fi
#             ;;
#         10)
#             echo "IP Options formats:"
#             echo "  R: Record route"
#             echo "  T: Timestamp"
#             echo "  U: Route record"
#             echo "  S addr: Loose source routing"
#             echo "  L addr: Strict source routing"
#             echo "  \hex: Custom hex values"
#             read -p "Enter IP options: " ip_options
#             if [ -n "$ip_options" ]; then
#                 evasion_options="$evasion_options --ip-options \"$ip_options\""
#                 echo "IP options set to: $ip_options"
#             else
#                 echo "No IP options provided."
#             fi
#             ;;
#         11)
#             read -p "Enter TTL value (1-255): " ttl
#             if [[ "$ttl" =~ ^[0-9]+$ ]] && [ "$ttl" -ge 1 ] && [ "$ttl" -le 255 ]; then
#                 evasion_options="$evasion_options --ttl $ttl"
#                 echo "TTL value set to: $ttl"
#             else
#                 echo "Invalid TTL value. Must be between 1 and 255."
#             fi
#             ;;
#         12)
#             echo "MAC address options:"
#             echo "  0: Use a random MAC address"
#             echo "  vendor: Use a random MAC from that vendor"
#             echo "  MAC: Use the specified MAC address"
#             read -p "Enter MAC address option: " mac
#             if [ -n "$mac" ]; then
#                 evasion_options="$evasion_options --spoof-mac $mac"
#                 echo "MAC spoofing set to: $mac"
#             else
#                 echo "No MAC address option provided."
#             fi
#             ;;
#         13)
#             evasion_options="$evasion_options --badsum"
#             echo "Bogus checksum option added"
#             ;;
#         14)
#             # Save evasion options to the global configuration before returning
#             SCAN_OPTIONS="$SCAN_OPTIONS $evasion_options"
#             echo "Firewall/IDS evasion options saved: $evasion_options"
#             echo "Returning to Main Menu..."
#             return_to_menu
#             break
#             ;;
#         "-h"|"--help")
#             display_help
#             ;;
#         *)
#             invalid_input
#             ;;
#         esac
#         read -p "Press Enter to continue..."
#     done
# }

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
        echo "12. Show Active Options"
        echo "13. Reset Command"
        echo "14. Run Nmap Scan"
        echo "15. Exit"
        echo "Type '-h' or '--help' for help"
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
                check_sudo
            fi
            read -p "Press Enter to continue..."
            ;;
            # if [[ -z "$nmap_args" ]]; then
            #     echo "No options selected yet."
            # else
            #     echo "Current Nmap Command: nmap $nmap_args"
            # fi
            # read -p "Press Enter to continue..."
            # ;;
        12)
            show_active_options
            ;;    
        13)
            nmap_args=""
            echo "Command reset successfully."
            read -p "Press Enter to continue..."
            ;;
        # 14)
        #     if [[ -z "$nmap_args" ]]; then
        #         echo "Error: No options selected. Please configure the scan first."
        #     else
        #         if [[ ! "$nmap_args" =~ -iL|-iR ]]; then
        #             prompt_input "Enter target (IP, hostname, or network): " target
        #             if [[ -n "$target" ]]; then
        #                 nmap_args+=" $target"
        #             else
        #                 echo "Error: Target cannot be empty."
        #                 read -p "Press Enter to continue..."
        #                 continue
        #             fi
        #         fi
        #         echo "Running: nmap $nmap_args"
        #         nmap $nmap_args
        #         nmap_args=""
        #     fi
        #     read -p "Press Enter to continue..."
        #     ;;
        14)
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
        15)
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
