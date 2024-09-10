#!/bin/bash
##H Usage: test_k8s_aps.sh <base_url> <url_list_file>
##H

# Replace Perl usage with standard UNIX tools
if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ] || [ "$1" == "help" ] || [ "$1" == "" ]; then
    grep "##H" $0 | sed -e "s,##H,,g"
    exit 1
fi

# Check if required arguments are provided
if [ $# -ne 2 ]; then
    echo "Error: You need to provide <base_url> and <url_list_file>"
    grep "##H" $0 | sed -e "s,##H,,g"
    exit 1
fi

X509_USER_KEY=$HOME/.globus/userkey.pem
X509_USER_CERT=$HOME/.globus/usercert.pem

base_url=$1
url_list_file=$2

# Check if the URL list file exists
if [ ! -f "$url_list_file" ]; then
    echo "Error: File $url_list_file not found!"
    exit 1
fi

# Function to perform the request with automatic redirect following
perform_request() {
    local target_url="$1"
    local cert="$2"
    local key="$3"
    final_status_code=$(curl -L -i --key "$key" --cert "$cert" -o /dev/null -w '%{http_code}' -s "$target_url")
    echo "  $target_url -> HTTP code: $final_status_code"
}

# Read the list of URLs from the file and process each
run_tests() {
    local cert="$1"
    local key="$2"
    current_section=""
    while read -r line; do
        # If the line is a comment, treat it as a section heading
        if [[ "$line" =~ ^#.*$ ]]; then
            section_header="${line/#\# /}"  # Remove "# " from the start of the comment
            if [[ "$section_header" != "$current_section" ]]; then
                current_section="$section_header"
                echo
                echo "== $current_section =="
            fi
        # If the line is not empty or a comment, process the URL
        elif [[ ! -z "$line" ]]; then
            perform_request "${base_url}${line}" "$cert" "$key"
        fi
    done < "$url_list_file"
}

# Run tests with X509_USER_CERT and X509_USER_KEY
echo "### Running tests with X509_USER_CERT and X509_USER_KEY"
run_tests "$X509_USER_CERT" "$X509_USER_KEY"

# Generate and use the proxy certificate
echo "### Running tests with X509_USER_PROXY"
unset X509_USER_PROXY
voms-proxy-init -voms cms -rfc
export X509_USER_PROXY=/tmp/x509up_u`id -u`

echo
echo "### Testing with proxy: $X509_USER_PROXY"
run_tests "$X509_USER_PROXY" "$X509_USER_PROXY"

