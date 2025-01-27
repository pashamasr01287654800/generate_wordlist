#!/bin/bash

# Function to display a progress bar
show_progress() {
    local progress=$1
    local total=$2
    local percent=$((progress * 100 / total))
    local bar_width=50
    local filled=$((percent * bar_width / 100))
    local empty=$((bar_width - filled))

    # Draw the progress bar
    printf "\r["
    printf "%0.s#" $(seq 1 $filled)
    printf "%0.s-" $(seq 1 $empty)
    printf "] %d%%" "$percent"
}

# Function to generate wordlist
generate_wordlist() {
    local min_length=$1
    local max_length=$2
    local charset=$3
    local wordlist_file=$4

    # Generate the wordlist using Bash
    generate_words() {
        local prefix=$1
        local length=$2
        if [ "$length" -eq 0 ]; then
            echo "$prefix" >> "$wordlist_file"
            ((current_progress++))
            show_progress "$current_progress" "$total_combinations"
        else
            for char in $(echo "$charset" | fold -w1); do
                generate_words "$prefix$char" $((length - 1))
            done
        fi
    }

    # Calculate the total number of combinations
    total_combinations=0
    charset_length=${#charset}
    for ((length=min_length; length<=max_length; length++)); do
        total_combinations=$((total_combinations + charset_length ** length))
    done

    # Initialize progress variables
    current_progress=0
    > "$wordlist_file"

    # Generate the wordlist with progress bar
    for ((length=min_length; length<=max_length; length++)); do
        generate_words "" "$length"
    done

    echo -e "\nWordlist has been generated and saved to $wordlist_file"
}

# Function to encrypt the wordlist
encrypt_wordlist() {
    local wordlist_file=$1
    local encryption_type=$2
    local output_file=$3
    local current_progress=0
    local total_combinations=$(wc -l < "$wordlist_file")

    while read -r word; do
        case $encryption_type in
            md5) echo -n "$word" | md5sum | awk '{print $1}' >> "$output_file" ;;
            sha1) echo -n "$word" | sha1sum | awk '{print $1}' >> "$output_file" ;;
            sha256) echo -n "$word" | sha256sum | awk '{print $1}' >> "$output_file" ;;
            sha512) echo -n "$word" | sha512sum | awk '{print $1}' >> "$output_file" ;;
            base64) echo -n "$word" | base64 >> "$output_file" ;;
            base32) echo -n "$word" | base32 >> "$output_file" ;;
        esac
        ((current_progress++))
        show_progress "$current_progress" "$total_combinations"
    done < "$wordlist_file"

    echo -e "\nThe wordlist has been encrypted and saved to $output_file"
}

# Display the main menu
while true; do
    echo ""
    echo "=============================="
    echo "Choose an option:"
    echo "1) Create and encrypt a new wordlist"
    echo "2) Encrypt an existing wordlist"
    echo "=============================="
    read -p "Enter your choice (1-2): " main_choice
    case "$main_choice" in
        1) 
            # If option 1 is chosen, generate a new wordlist and ask for encryption
            while true; do
                read -p "Enter the minimum password length: " min_length
                if [[ "$min_length" =~ ^[0-9]+$ ]] && [ "$min_length" -gt 0 ]; then
                    break
                else
                    echo "Invalid input. Please enter a positive number."
                fi
            done

            while true; do
                read -p "Enter the maximum password length: " max_length
                if [[ "$max_length" =~ ^[0-9]+$ ]] && [ "$max_length" -ge "$min_length" ]; then
                    break
                else
                    echo "Invalid input. Please enter a number greater than or equal to the minimum length."
                fi
            done

            # Ask the user for the character set
            while true; do
                read -p "Enter the character set for the wordlist (e.g., abc123): " charset
                if [[ -n "$charset" ]]; then
                    break
                else
                    echo "Character set cannot be empty. Please try again."
                fi
            done

            # Ask the user for the wordlist output file name
            while true; do
                read -p "Enter the filename to save the wordlist: " wordlist_file
                if [[ -n "$wordlist_file" ]]; then
                    break
                else
                    echo "Filename cannot be empty. Please try again."
                fi
            done

            # Generate the wordlist
            generate_wordlist "$min_length" "$max_length" "$charset" "$wordlist_file"

            # Ask the user if they want to encrypt the wordlist
            while true; do
                read -p "Do you want to encrypt the wordlist? (yes/y or no/n): " encrypt_choice
                case "$encrypt_choice" in
                    yes|y)
                        encrypt=true
                        break
                        ;;
                    no|n)
                        encrypt=false
                        break
                        ;;
                    *)
                        echo "Invalid input. Please answer with yes/y or no/n."
                        ;;
                esac
            done

            if $encrypt; then
                # Display encryption options with validation (starting from 1)
                while true; do
                    echo ""
                    echo "=============================="
                    echo "Choose an encryption method from the options below:"
                    echo "1) MD5"
                    echo "2) SHA1"
                    echo "3) SHA256"
                    echo "4) SHA512"
                    echo "5) Base64"
                    echo "6) Base32"
                    echo "=============================="
                    
                    # Ask for the encryption option
                    read -p "Enter your choice (1-6): " encryption_option
                    if [[ "$encryption_option" =~ ^[1-6]$ ]]; then
                        break
                    else
                        echo "Invalid option. Please enter a number between 1 and 6."
                    fi
                done

                # Apply encryption based on the user's choice
                case $encryption_option in
                    1) encrypt_wordlist "$wordlist_file" "md5" "encrypted_$wordlist_file" ;;
                    2) encrypt_wordlist "$wordlist_file" "sha1" "encrypted_$wordlist_file" ;;
                    3) encrypt_wordlist "$wordlist_file" "sha256" "encrypted_$wordlist_file" ;;
                    4) encrypt_wordlist "$wordlist_file" "sha512" "encrypted_$wordlist_file" ;;
                    5) encrypt_wordlist "$wordlist_file" "base64" "encrypted_$wordlist_file" ;;
                    6) encrypt_wordlist "$wordlist_file" "base32" "encrypted_$wordlist_file" ;;
                esac
            fi
            break
            ;;
        2) 
            # If option 2 is chosen, ask for an existing wordlist file to encrypt
            while true; do
                read -p "Enter the path to the wordlist you want to encrypt: " wordlist_file
                if [[ -f "$wordlist_file" ]]; then
                    break
                else
                    echo "File not found. Please try again."
                fi
            done

            # Display encryption options and encrypt the file
            while true; do
                echo ""
                echo "=============================="
                echo "Choose an encryption method from the options below:"
                echo "1) MD5"
                echo "2) SHA1"
                echo "3) SHA256"
                echo "4) SHA512"
                echo "5) Base64"
                echo "6) Base32"
                echo "=============================="
                
                # Ask for the encryption option
                read -p "Enter your choice (1-6): " encryption_option
                if [[ "$encryption_option" =~ ^[1-6]$ ]]; then
                    break
                else
                    echo "Invalid option. Please enter a number between 1 and 6."
                fi
            done

            # Apply encryption based on the user's choice
            case $encryption_option in
                1) encrypt_wordlist "$wordlist_file" "md5" "encrypted_$wordlist_file" ;;
                2) encrypt_wordlist "$wordlist_file" "sha1" "encrypted_$wordlist_file" ;;
                3) encrypt_wordlist "$wordlist_file" "sha256" "encrypted_$wordlist_file" ;;
                4) encrypt_wordlist "$wordlist_file" "sha512" "encrypted_$wordlist_file" ;;
                5) encrypt_wordlist "$wordlist_file" "base64" "encrypted_$wordlist_file" ;;
                6) encrypt_wordlist "$wordlist_file" "base32" "encrypted_$wordlist_file" ;;
            esac
            break
            ;;
        *)
            echo "Invalid choice. Please select 1 or 2."
            ;;
    esac
done
