#!/system/bin/sh
#
# AFN Keys Grabber for Hi3798MV200 Android STB
# Simple shell script to extract AFN PowerVu keys from LinuxSat forum
# Usage: ./afn_keys_grabber.sh
#

# Colors for output (if terminal supports it)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FORUM_URL="https://www.linuxsat-support.com/thread/152939-only-afn-powervu-keys-no-chat-keys-only/"
TEMP_DIR="/data/local/tmp/afn_grabber"
OUTPUT_FILE="$TEMP_DIR/afn_keys.txt"
SOFTCAM_KEY="/data/data/com.orcagold.plugin/softcam_emulator/softcam.key"
USER_AGENT="Mozilla/5.0 (Linux; Android 7.0; Hi3798MV200) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Safari/537.36"

# Create temp directory
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

echo -e "${BLUE}🔍 AFN Keys Grabber for Android STB${NC}"
echo -e "${BLUE}=====================================${NC}"
echo -e "${YELLOW}📱 STB Model: Hi3798MV200 Android 7.0${NC}"
echo -e "${YELLOW}🌐 Forum: LinuxSat-Support${NC}"
echo ""

# Function to log with timestamp
log() {
    echo -e "[$(date '+%H:%M:%S')] $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to download forum page
download_forum_page() {
    local url="$1"
    local output="$2"
    
    log "${BLUE}🌐 Downloading forum page...${NC}"
    
    # Try different download methods available on Android
    if command_exists curl; then
        log "${GREEN}Using curl${NC}"
        curl -s -L \
            -H "User-Agent: $USER_AGENT" \
            -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
            -H "Accept-Language: en-US,en;q=0.5" \
            -H "Accept-Encoding: gzip, deflate" \
            -H "Connection: keep-alive" \
            --connect-timeout 30 \
            --max-time 60 \
            --retry 3 \
            "$url" > "$output"
        return $?
    elif command_exists wget; then
        log "${GREEN}Using wget${NC}"
        wget -q \
            --user-agent="$USER_AGENT" \
            --header="Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
            --header="Accept-Language: en-US,en;q=0.5" \
            --header="Connection: keep-alive" \
            --timeout=30 \
            --tries=3 \
            -O "$output" \
            "$url"
        return $?
    elif [ -f /system/bin/wget ]; then
        log "${GREEN}Using system wget${NC}"
        /system/bin/wget -q -O "$output" "$url"
        return $?
    else
        log "${RED}❌ No download tool available (curl/wget)${NC}"
        return 1
    fi
}

# Function to find last page number
find_last_page() {
    local html_file="$1"
    
    if [ ! -f "$html_file" ]; then
        echo "1"
        return
    fi
    
    # Extract page numbers using grep and sed
    # Look for patterns like: pageNo=123 or page=123
    local max_page=$(grep -o 'pageNo=[0-9]\+\|page=[0-9]\+' "$html_file" 2>/dev/null | \
                    sed 's/.*=//g' | \
                    sort -n | \
                    tail -1)
    
    if [ -z "$max_page" ] || [ "$max_page" -eq 0 ]; then
        echo "1"
    else
        echo "$max_page"
    fi
}

# Function to extract AFN keys from HTML
extract_afn_keys() {
    local html_file="$1"
    local key_00=""
    local key_01=""
    
    if [ ! -f "$html_file" ]; then
        log "${RED}❌ HTML file not found: $html_file${NC}"
        return 1
    fi
    
    log "${BLUE}🔍 Extracting AFN keys from forum content...${NC}"
    
    # Remove HTML tags and extract text content
    # Use sed to remove HTML tags (basic cleanup)
    sed 's/<[^>]*>//g' "$html_file" > "$TEMP_DIR/clean_text.txt"
    
    # Extract AFN keys using grep and sed
    # Look for patterns like: 00: 1234567890ABCDEF or 00 1234567890ABCDEF
    key_00=$(grep -i '00[[:space:]]*[:]*[[:space:]]*[A-Fa-f0-9]\{14,32\}' "$TEMP_DIR/clean_text.txt" | \
             sed -n 's/.*00[[:space:]]*[:]*[[:space:]]*\([A-Fa-f0-9]\{14,32\}\).*/\1/p' | \
             tail -1 | \
             tr '[:lower:]' '[:upper:]')
    
    key_01=$(grep -i '01[[:space:]]*[:]*[[:space:]]*[A-Fa-f0-9]\{14,32\}' "$TEMP_DIR/clean_text.txt" | \
             sed -n 's/.*01[[:space:]]*[:]*[[:space:]]*\([A-Fa-f0-9]\{14,32\}\).*/\1/p' | \
             tail -1 | \
             tr '[:lower:]' '[:upper:]')
    
    # Alternative patterns - look for AFN, PowerVu context
    if [ -z "$key_00" ]; then
        key_00=$(grep -A5 -B5 -i 'afn\|powervu\|0009ffff' "$TEMP_DIR/clean_text.txt" | \
                 grep -i '00[[:space:]]*[:]*[[:space:]]*[A-Fa-f0-9]\{14,32\}' | \
                 sed -n 's/.*00[[:space:]]*[:]*[[:space:]]*\([A-Fa-f0-9]\{14,32\}\).*/\1/p' | \
                 tail -1 | \
                 tr '[:lower:]' '[:upper:]')
    fi
    
    if [ -z "$key_01" ]; then
        key_01=$(grep -A5 -B5 -i 'afn\|powervu\|0009ffff' "$TEMP_DIR/clean_text.txt" | \
                 grep -i '01[[:space:]]*[:]*[[:space:]]*[A-Fa-f0-9]\{14,32\}' | \
                 sed -n 's/.*01[[:space:]]*[:]*[[:space:]]*\([A-Fa-f0-9]\{14,32\}\).*/\1/p' | \
                 tail -1 | \
                 tr '[:lower:]' '[:upper:]')
    fi
    
    # Output results
    if [ -n "$key_00" ] || [ -n "$key_01" ]; then
        log "${GREEN}✅ AFN Keys extracted successfully!${NC}"
        echo ""
        echo -e "${GREEN}🔑 AFN PowerVu Keys Found:${NC}"
        echo -e "${GREEN}=========================${NC}"
        
        if [ -n "$key_00" ]; then
            echo -e "${YELLOW}AFN 00: ${GREEN}$key_00${NC}"
        else
            echo -e "${YELLOW}AFN 00: ${RED}Not found${NC}"
        fi
        
        if [ -n "$key_01" ]; then
            echo -e "${YELLOW}AFN 01: ${GREEN}$key_01${NC}"
        else
            echo -e "${YELLOW}AFN 01: ${RED}Not found${NC}"
        fi
        
        # Save to output file
        {
            echo "AFN PowerVu Keys - Extracted $(date)"
            echo "=========================================="
            echo "Forum: $FORUM_URL"
            echo "Extracted: $(date '+%Y-%m-%d %H:%M:%S')"
            echo ""
            if [ -n "$key_00" ]; then
                echo "AFN 00: $key_00"
            fi
            if [ -n "$key_01" ]; then
                echo "AFN 01: $key_01"
            fi
            echo ""
            echo "SoftCam.Key format:"
            echo "P 9798A8F2 GROUP 0009 ; American Forces Network"
            if [ -n "$key_00" ]; then
                echo "P 0009FFFF 00 $key_00 ;ecm key"
            fi
            if [ -n "$key_01" ]; then
                echo "P 0009FFFF 01 $key_01 ;ecm key"
            fi
        } > "$OUTPUT_FILE"
        
        log "${GREEN}💾 Keys saved to: $OUTPUT_FILE${NC}"
        
        return 0
    else
        log "${RED}❌ No AFN keys found in forum content${NC}"
        return 1
    fi
}

# Function to update SoftCam.Key file
update_softcam_key() {
    local key_00="$1"
    local key_01="$2"
    
    if [ -z "$key_00" ] && [ -z "$key_01" ]; then
        log "${YELLOW}⚠️ No keys to update${NC}"
        return 1
    fi
    
    log "${BLUE}📝 Updating SoftCam.Key file...${NC}"
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$SOFTCAM_KEY")"
    
    if [ ! -f "$SOFTCAM_KEY" ]; then
        log "${YELLOW}📄 Creating new SoftCam.Key file${NC}"
        {
            echo ";----------------- AFN PowerVu Keys -----------------"
            echo "P 9798A8F2 GROUP 0009 ; American Forces Network"
            if [ -n "$key_00" ]; then
                echo "P 0009FFFF 00 $key_00 ;ecm key"
            fi
            if [ -n "$key_01" ]; then
                echo "P 0009FFFF 01 $key_01 ;ecm key"
            fi
        } > "$SOFTCAM_KEY"
    else
        log "${YELLOW}📝 Updating existing SoftCam.Key file${NC}"
        
        # Create backup
        cp "$SOFTCAM_KEY" "$SOFTCAM_KEY.backup"
        
        # Create temporary file with updates
        temp_file="$TEMP_DIR/softcam_temp.key"
        
        # Process existing file
        while IFS= read -r line; do
            if echo "$line" | grep -q "P 0009FFFF 00" && [ -n "$key_00" ]; then
                echo "P 0009FFFF 00 $key_00 ;ecm key"
            elif echo "$line" | grep -q "P 0009FFFF 01" && [ -n "$key_01" ]; then
                echo "P 0009FFFF 01 $key_01 ;ecm key"
            else
                echo "$line"
            fi
        done < "$SOFTCAM_KEY" > "$temp_file"
        
        # Add keys if they weren't found in existing file
        if [ -n "$key_00" ] && ! grep -q "P 0009FFFF 00" "$SOFTCAM_KEY"; then
            echo "P 0009FFFF 00 $key_00 ;ecm key" >> "$temp_file"
        fi
        
        if [ -n "$key_01" ] && ! grep -q "P 0009FFFF 01" "$SOFTCAM_KEY"; then
            echo "P 0009FFFF 01 $key_01 ;ecm key" >> "$temp_file"
        fi
        
        # Replace original file
        mv "$temp_file" "$SOFTCAM_KEY"
    fi
    
    # Set proper permissions
    chmod 644 "$SOFTCAM_KEY" 2>/dev/null || true
    
    log "${GREEN}✅ SoftCam.Key updated successfully${NC}"
    return 0
}

# Function to show debug info
show_debug_info() {
    echo ""
    echo -e "${BLUE}🐛 Debug Information:${NC}"
    echo -e "${BLUE}===================${NC}"
    echo -e "${YELLOW}OS Info:${NC} $(uname -a 2>/dev/null || echo 'Unknown')"
    echo -e "${YELLOW}Shell:${NC} $0"
    echo -e "${YELLOW}Available tools:${NC}"
    
    for tool in curl wget grep sed tail sort; do
        if command_exists "$tool"; then
            echo -e "  ✅ $tool: $(which "$tool" 2>/dev/null || echo 'available')"
        else
            echo -e "  ❌ $tool: not found"
        fi
    done
    
    echo -e "${YELLOW}Paths:${NC}"
    echo -e "  📁 Temp dir: $TEMP_DIR"
    echo -e "  📄 Output file: $OUTPUT_FILE"
    echo -e "  🔑 SoftCam.Key: $SOFTCAM_KEY"
    echo ""
}

# Main execution
main() {
    local debug_mode=false
    local update_softcam=false
    
    # Parse command line arguments
    while [ $# -gt 0 ]; do
        case $1 in
            --debug|-d)
                debug_mode=true
                shift
                ;;
            --update|-u)
                update_softcam=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  -d, --debug    Show debug information"
                echo "  -u, --update   Update SoftCam.Key file"
                echo "  -h, --help     Show this help message"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    if [ "$debug_mode" = true ]; then
        show_debug_info
    fi
    
    # Step 1: Download main forum page
    log "${BLUE}📥 Step 1: Downloading main forum page${NC}"
    if ! download_forum_page "$FORUM_URL" "$TEMP_DIR/main_page.html"; then
        log "${RED}❌ Failed to download main forum page${NC}"
        exit 1
    fi
    
    # Step 2: Find last page
    log "${BLUE}🔍 Step 2: Finding last page number${NC}"
    last_page=$(find_last_page "$TEMP_DIR/main_page.html")
    log "${GREEN}📄 Last page found: $last_page${NC}"
    
    # Step 3: Download last page if different from main
    if [ "$last_page" != "1" ]; then
        last_page_url="${FORUM_URL}?pageNo=${last_page}"
        log "${BLUE}📥 Step 3: Downloading last page: $last_page_url${NC}"
        if ! download_forum_page "$last_page_url" "$TEMP_DIR/last_page.html"; then
            log "${YELLOW}⚠️ Failed to download last page, using main page${NC}"
            cp "$TEMP_DIR/main_page.html" "$TEMP_DIR/last_page.html"
        fi
    else
        cp "$TEMP_DIR/main_page.html" "$TEMP_DIR/last_page.html"
    fi
    
    # Step 4: Extract AFN keys
    log "${BLUE}🔑 Step 4: Extracting AFN keys${NC}"
    if extract_afn_keys "$TEMP_DIR/last_page.html"; then
        # Step 5: Update SoftCam.Key if requested
        if [ "$update_softcam" = true ]; then
            log "${BLUE}💾 Step 5: Updating SoftCam.Key file${NC}"
            
            # Extract keys from output file
            key_00=$(grep "AFN 00:" "$OUTPUT_FILE" 2>/dev/null | cut -d' ' -f3)
            key_01=$(grep "AFN 01:" "$OUTPUT_FILE" 2>/dev/null | cut -d' ' -f3)
            
            if update_softcam_key "$key_00" "$key_01"; then
                log "${GREEN}🎉 Process completed successfully!${NC}"
                echo ""
                echo -e "${GREEN}Summary:${NC}"
                echo -e "${GREEN}========${NC}"
                echo -e "${YELLOW}✅ Keys extracted from forum${NC}"
                echo -e "${YELLOW}✅ SoftCam.Key file updated${NC}"
                echo -e "${YELLOW}📄 Results saved to: $OUTPUT_FILE${NC}"
                echo -e "${YELLOW}🔑 SoftCam.Key updated: $SOFTCAM_KEY${NC}"
            else
                log "${RED}❌ Failed to update SoftCam.Key file${NC}"
                exit 1
            fi
        else
            log "${GREEN}🎉 Keys extracted successfully!${NC}"
            echo ""
            echo -e "${YELLOW}💡 To update SoftCam.Key file, run with -u flag:${NC}"
            echo -e "${BLUE}   $0 -u${NC}"
        fi
    else
        log "${RED}❌ Failed to extract AFN keys${NC}"
        exit 1
    fi
    
    # Cleanup
    log "${BLUE}🧹 Cleaning up temporary files${NC}"
    rm -f "$TEMP_DIR/main_page.html" "$TEMP_DIR/last_page.html" "$TEMP_DIR/clean_text.txt" 2>/dev/null || true
    
    echo ""
    log "${GREEN}✅ AFN Keys Grabber completed successfully!${NC}"
}

# Run main function with all arguments
main "$@"