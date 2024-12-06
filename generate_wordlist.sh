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

# Ask the user for the minimum and maximum password length
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

# Encryption section with progress bar
encrypt_wordlist() {
    local encryption_type=$1
    local output_file=$2

    current_progress=0
    total_combinations=$(wc -l < "$wordlist_file")

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
}

# Display encryption options
echo ""
echo "=============================="
echo "Choose an encryption method from the options below:"
echo "0) No encryption (keep the wordlist as is)"
echo "1) MD5"
echo "2) SHA1"
echo "3) SHA256"
echo "4) SHA512"
echo "5) Base64"
echo "6) Base32"
echo "=============================="

# Ask for the encryption option
while true; do
    read -p "Enter your choice (0-6): " encryption_option
    if [[ "$encryption_option" =~ ^[0-6]$ ]]; then
        break
    else
        echo "Invalid option. Please enter a number between 0 and 6."
    fi
done

# Apply encryption based on the user's choice
case $encryption_option in
    0)
        echo "The wordlist has been generated without encryption and saved in $wordlist_file"
        ;;
    1)
        encrypted_file="encrypted_$wordlist_file"
        encrypt_wordlist "md5" "$encrypted_file"
        echo -e "\nThe wordlist has been encrypted with MD5 and saved in $encrypted_file"
        ;;
    2)
        encrypted_file="encrypted_$wordlist_file"
        encrypt_wordlist "sha1" "$encrypted_file"
        echo -e "\nThe wordlist has been encrypted with SHA1 and saved in $encrypted_file"
        ;;
    3)
        encrypted_file="encrypted_$wordlist_file"
        encrypt_wordlist "sha256" "$encrypted_file"
        echo -e "\nThe wordlist has been encrypted with SHA256 and saved in $encrypted_file"
        ;;
    4)
        encrypted_file="encrypted_$wordlist_file"
        encrypt_wordlist "sha512" "$encrypted_file"
        echo -e "\nThe wordlist has been encrypted with SHA512 and saved in $encrypted_file"
        ;;
    5)
        encrypted_file="encrypted_$wordlist_file"
        encrypt_wordlist "base64" "$encrypted_file"
        echo -e "\nThe wordlist has been encrypted with Base64 and saved in $encrypted_file"
        ;;
    6)
        encrypted_file="encrypted_$wordlist_file"
        encrypt_wordlist "base32" "$encrypted_file"
        echo -e "\nThe wordlist has been encrypted with Base32 and saved in $encrypted_file"
        ;;
esac
