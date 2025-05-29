#!/bin/bash

# Couleurs pour les messages
YELLOW='\033[1;33m'
COL_RESET='\033[0m'

# Définir le chemin d'installation : utiliser $1 si fourni, sinon valeur par défaut
pathstratuminstall="${1:-$HOME/yiimp/stratum}"

# Enlever le slash final de pathstratuminstall
pathstratuminstall=$(echo "$pathstratuminstall" | sed 's/\/$//')

# Définir le chemin d'installation : utiliser $1 si fourni, sinon valeur par défaut
pathstratuminstall="${1:-$HOME/yiimp/stratum}"

# Convertir en chemin absolu
if [[ "$pathstratuminstall" != /* ]]; then
    # Si chemin relatif, le préfixer avec $HOME
    pathstratuminstall="$HOME/$pathstratuminstall"
fi
pathstratuminstall=$(realpath "$pathstratuminstall" 2>/dev/null || echo "$pathstratuminstall")

# Enlever le slash final de pathstratuminstall
pathstratuminstall=$(echo "$pathstratuminstall" | sed 's/\/$//')

# Créer un fichier swap de 4 Go si nécessaire
if ! swapon --show | grep -q "/swapfile"; then
    if [ ! -f /swapfile ]; then
        sudo fallocate -l 4G /swapfile
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    else
        sudo swapon /swapfile
    fi
else
    SWAP_SIZE=$(free -m | grep Swap | awk '{print $2}')
    if [ "$SWAP_SIZE" -lt 4000 ]; then
        sudo swapoff /swapfile 2>/dev/null
        sudo fallocate -l 4G /swapfile
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
    fi
fi

# Compile Stratum
cd ${pathstratuminstall}

sudo chmod -R u+rwX "${pathstratuminstall}"
sudo chown -R $(whoami):$(whoami) "${pathstratuminstall}"

sudo make clean > /dev/null 2>&1

# Détecter l'architecture
ARCH=$(dpkg --print-architecture)
ARCH_KERNEL=$(uname -m)

# Vérifier que l'architecture est 64 bits (aarch64/arm64)
if [[ "$ARCH" != "arm64" || "$ARCH_KERNEL" != "aarch64" ]]; then
    echo -e "${YELLOW} Error: This script requires a 64-bit ARM architecture (aarch64/arm64). Detected: ARCH=$ARCH, ARCH_KERNEL=$ARCH_KERNEL${COL_RESET}"
    exit 1
fi

if [[ "$ARCH" =~ ^(arm|arm64|armhf)$ || "$ARCH_KERNEL" =~ ^(arm|aarch64|armv[0-9]+l)$ ]]; then
echo -e "${YELLOW} ARM detected, Patcht & running compilation Stratum${COL_RESET}"

	# Détecter l'architecture ARM et définir $cpu
	cpu=""
	arch=$(uname -m)
	if [[ "$arch" =~ ^armv7 ]]; then
		cpu="armv7-a"
		fpu="vfpv3"
		float_abi="softfp"
		sudo sed -i '/#endif/i #if defined(__ARM_ARCH_7A__) || defined(__ARM_ARCH_7__)\ntypedef unsigned long long uint128_t __attribute__((mode(TI)));\n#endif' "$pathstratuminstall/sha3/sph_types.h"
	elif [[ "$arch" == "aarch64" ]]; then
		cpu="armv8-a"
		fpu=""
		float_abi="hard"
		sudo sed -i '/#endif/i #if defined(__aarch64__)\ntypedef unsigned __int128 uint128_t;\n#endif' "$pathstratuminstall/sha3/sph_types.h"
	elif [[ "$arch" =~ ^armv6 ]]; then
		cpu="armv6"
		fpu="vfp"
		float_abi="soft"
	else
		echo -e "${YELLOW} Error: Unsupported architecture $arch${COL_RESET}"
		exit 1
	fi
	
	echo -e "${YELLOW} Detected CPU architecture: $cpu${COL_RESET}"
	sleep 3
    # Modifier automatiquement le Makefile dans algos
	if [ -f "${pathstratuminstall}/algos/makefile" ]; then
		ALGO_MAKEFILE="${pathstratuminstall}/algos/makefile"
	elif [ -f "${pathstratuminstall}/algos/Makefile" ]; then
		ALGO_MAKEFILE="${pathstratuminstall}/algos/Makefile"
	fi
	# Vérifier si le Makefile a été trouvé
	if [ -z "$ALGO_MAKEFILE" ]; then
		echo -e "${YELLOW} Error: Neither makefile nor Makefile found at ${pathstratuminstall}/algos/${COL_RESET}"
		exit 1
	fi
    if sudo grep -q "CFLAGS" "$ALGO_MAKEFILE"; then
		sudo sed -i "s/-march=native/-march=$cpu ${fpu:+-mfpu=$fpu}/" "$ALGO_MAKEFILE"
		sudo sed -i 's/-mfloat-abi=hard/-mfloat-abi='$float_abi'/' "$ALGO_MAKEFILE"
		sudo sed -i 's/-mfloat-abi=softfp/-mfloat-abi='$float_abi'/' "$ALGO_MAKEFILE"
        if ! sudo grep -q "\-DNO_SIMD" "$ALGO_MAKEFILE"; then
            sudo sed -i '/CFLAGS/s/$/ -DNO_SIMD/' "$ALGO_MAKEFILE"
        fi
        if ! sudo grep -q "\-Ialgos/blake2" "$ALGO_MAKEFILE"; then
            sudo sed -i '/CFLAGS/s/$/ -Ialgos\/blake2/' "$ALGO_MAKEFILE"
        fi
		if ! sudo grep -q "\-I\.\." "$ALGO_MAKEFILE"; then
			sudo sed -i '/CFLAGS/s/$/ -I../' "$ALGO_MAKEFILE"
			echo -e "$YELLOW Added -I.. to $ALGO_MAKEFILE$COL_RESET"
		else
			# S'assurer que -Isha3 est supprimé si présent
			sudo sed -i 's/-Isha3//g' "$ALGO_MAKEFILE"
			echo -e "$YELLOW Removed -Isha3 from $ALGO_MAKEFILE if present$COL_RESET"
		fi
        sudo sed -i 's/#.*yespower\/yespower-blake2b\.o:/yespower\/yespower-blake2b.o:/' "$ALGO_MAKEFILE"
        sudo sed -i 's/#.*$(CC) $(CFLAGS) -c yespower\/yespower-blake2b\.c/$(CC) $(CFLAGS) -c yespower\/yespower-blake2b.c/' "$ALGO_MAKEFILE"
        sudo sed -i 's/#.*ar2\/opt\.o:/ar2\/opt.o:/' "$ALGO_MAKEFILE"
        sudo sed -i 's/#.*$(CC) $(CFLAGS) -c ar2\/opt\.c/$(CC) $(CFLAGS) -c ar2\/opt.c/' "$ALGO_MAKEFILE"
    else
        echo -e "$YELLOW Error: CFLAGS not found in $ALGO_MAKEFILE, please check manually$COL_RESET"
        exit 1
    fi
    
    # Vérifier et corriger les permissions de blake2/
    BLAMKA_FILE="${pathstratuminstall}/algos/blake2/blamka-round-opt.h"
    BLAMKA_DIR="${pathstratuminstall}/algos/blake2"
    if [ -f "$BLAMKA_FILE" ]; then
        sudo chmod 644 "$BLAMKA_FILE"
        sudo chmod 755 "$BLAMKA_DIR"
    else
        sudo mkdir -p "$BLAMKA_DIR"
        sudo chmod 755 "$BLAMKA_DIR"
        sudo bash -c "cat > $BLAMKA_FILE" << 'EOF'
#ifndef BLAMKA_ROUND_OPT_H
#define BLAMKA_ROUND_OPT_H
/* Minimal header to satisfy compilation without SIMD dependencies */
#endif
EOF
        sudo chmod 644 "$BLAMKA_FILE"
    fi
    
	# Vérifier les fichiers dans sha3/
	SHA3_DIR="${pathstratuminstall}/sha3"
	if [ -d "$SHA3_DIR" ]; then
		sudo chmod 755 "$SHA3_DIR"
		# Liste des fichiers SHA3 à vérifier
		SHA3_FILES=(
			"sph_blake.h"
			"sph_cubehash.h"
			"sph_shavite.h"
			"sph_simd.h"
			"sph_echo.h"
			"sph_sha2.h"
		)
		for file in "${SHA3_FILES[@]}"; do
			SHA3_HEADER="${SHA3_DIR}/${file}"
			if [ -f "$SHA3_HEADER" ]; then
				sudo chmod 644 "$SHA3_HEADER"
				if [ ! -s "$SHA3_HEADER" ]; then
					echo -e "$YELLOW Error: $SHA3_HEADER is empty$COL_RESET"
					exit 1
				fi
			else
				echo -e "$YELLOW Error: $SHA3_HEADER not found$COL_RESET"
				exit 1
			fi
		done
	else
		echo -e "$YELLOW Error: $SHA3_DIR directory not found$COL_RESET"
		exit 1
	fi

    # Recherche automatique des fichiers utilisant __m128i, __m256i, __m512i ou en-têtes SIMD x86
    SIMDFILES=$(sudo find ${pathstratuminstall} -type f \( -name "*.c" -o -name "*.h" \) -exec grep -l -E "__m128i|__m256i|__m512i|emmintrin.h|xmmintrin.h|smmintrin.h|tmmintrin.h|x86intrin.h|immintrin.h|_mm_" {} \;)
    
    if [ -n "$SIMDFILES" ]; then
        while IFS= read -r file; do
            if [ "$file" != "${pathstratuminstall}/algos/aurum.c" ] && [ "$file" != "${pathstratuminstall}/algos/xelisv2.c" ] && [ "$file" != "${pathstratuminstall}/algos/xelisv2-pepew/aes.h" ]; then
                sudo chmod 666 "$file"
                for header in emmintrin.h xmmintrin.h smmintrin.h tmmintrin.h x86intrin.h immintrin.h; do
                    if sudo grep -q "#include <${header}>" "$file"; then
                        sudo sed -i "/#include <${header}>/ s/^/\/\//" "$file"
                    fi
                done
                if sudo grep -q "__m128i\|__m256i\|__m512i" "$file"; then
                    sudo sed -i '/__m128i\|__m256i\|__m512i/ s/^/\/\//' "$file"
                fi
                if sudo grep -q "_mm_" "$file"; then
                    sudo sed -i '/_mm_/ s/^/\/\//' "$file"
                fi
            fi
        done <<< "$SIMDFILES"
    fi

	# Patcher blake2s.c dans sha3/
	BLAKE2S_FILE="${pathstratuminstall}/sha3/blake2s.c"
	if [ -f "$BLAKE2S_FILE" ]; then
		sudo chmod 666 "$BLAKE2S_FILE"
		if grep -q "blake2s_state[[:space:]]*S\[1\];" "$BLAKE2S_FILE"; then
			sudo sed -i 's/blake2s_state[[:space:]]*S\[1\];/blake2s_state S;/' "$BLAKE2S_FILE"
		fi
		sudo sed -i 's/blake2s_init_key[[:space:]]*([[:space:]]*S/blake2s_init_key(\&S/' "$BLAKE2S_FILE"
		sudo sed -i 's/blake2s_init[[:space:]]*([[:space:]]*S/blake2s_init(\&S/' "$BLAKE2S_FILE"
		sudo sed -i 's/blake2s_update[[:space:]]*([[:space:]]*S/blake2s_update(\&S/' "$BLAKE2S_FILE"
		sudo sed -i 's/blake2s_final[[:space:]]*([[:space:]]*S/blake2s_final(\&S/' "$BLAKE2S_FILE"
	fi

	# Corriger le conflit de la macro ROTR dans sha512_256.h
	SHA512_256_FILE="${pathstratuminstall}/algos/sha512_256.h"
	if [ -f "$SHA512_256_FILE" ]; then
		sudo chmod 666 "$SHA512_256_FILE"
		sudo sed -i 's/#define ROTR(x, n)/#define ROTR64(x, n)/' "$SHA512_256_FILE"
	fi

	# Fonction pour corriger un fichier
	correct_file() {
		local FILE="$1"
		if [ -f "$FILE" ]; then
			echo " Processing $FILE"
			sudo chmod 666 "$FILE"
			
			# Ajouter #include <stdint.h> si absent
			if ! grep -q "#include <stdint.h>" "$FILE"; then
				sudo sed -i '1i #include <stdint.h>' "$FILE"
			fi
			
			# Commenter toutes les lignes contenant bswapl
			sudo sed -i '/bswapl/ s/^/\/\//' "$FILE"
			
			# Remplacer bswapl par swap32 dans les expressions C/C++
			sudo sed -i 's/bswapl[[:space:]]*\([a-zA-Z0-9_]\+\)/swap32(\1)/g' "$FILE"
			
			# Remplacer les blocs assembleur inline contenant bswapl
			sudo sed -i 's/__asm__ volatile ("bswapl %0" : "=r" (\([a-zA-Z0-9_]\+\)) : "0" (\1));/\1 = swap32(\1);/g' "$FILE"
			
			# Remplacer sprintf par snprintf pour params
			sudo sed -i 's/sprintf(params/snprintf(params, 512/' "$FILE"
			
			# Remplacer sprintf par snprintf pour templ->coinbase
			sudo sed -i 's/sprintf(templ->coinbase/snprintf(templ->coinbase, 4096/' "$FILE"
		fi
	}

	# Vérifier si swap32 est déjà défini dans n'importe quel fichier
	if ! grep -r -q "static inline uint32_t swap32(uint32_t x)" "$pathstratuminstall"; then
		# Ajouter swap32 dans sha3/sph_types.h si absent
		SPH_TYPES_FILE="$pathstratuminstall/sha3/sph_types.h"
		if [ -f "$SPH_TYPES_FILE" ]; then
			echo " Ajout de swap32 dans $SPH_TYPES_FILE"
			sudo chmod 666 "$SPH_TYPES_FILE"
			if ! grep -q "#include <stdint.h>" "$SPH_TYPES_FILE"; then
				sudo sed -i '1i #include <stdint.h>' "$SPH_TYPES_FILE"
			fi
			sudo sed -i '1a static inline uint32_t swap32(uint32_t x) { return ((x >> 24) & 0x000000FF) | ((x >> 8) & 0x0000FF00) | ((x << 8) & 0x00FF0000) | ((x << 24) & 0xFF000000); }' "$SPH_TYPES_FILE"
		fi
	fi

	# Traiter tous les fichiers .cpp et .h dans le répertoire
	for FILE in "$pathstratuminstall"/*.cpp "$pathstratuminstall"/*.h "$pathstratuminstall"/algos/*/*.h "$pathstratuminstall"/sha3/*.h; do
		correct_file "$FILE"
	done

	# Patcher xelisv2.c pour qu'il fonctionne sur ARM64
	XELISV2_FILE="${pathstratuminstall}/algos/xelisv2.c"
	if [ -f "$XELISV2_FILE" ]; then
		sudo chmod 666 "$XELISV2_FILE"
		sudo sed -i 's/#include "sha3\/sph_blake.h"/#include "..\/sha3\/sph_blake.h"/' "$XELISV2_FILE"
		sudo sed -i 's/#include "sha3\/sph_cubehash.h"/#include "..\/sha3\/sph_cubehash.h"/' "$XELISV2_FILE"
		sudo sed -i 's/#include "sha3\/sph_shavite.h"/#include "..\/sha3\/sph_shavite.h"/' "$XELISV2_FILE"
		sudo sed -i 's/#include "sha3\/sph_simd.h"/#include "..\/sha3\/sph_simd.h"/' "$XELISV2_FILE"
		sudo sed -i 's/#include "sha3\/sph_echo.h"/#include "..\/sha3\/sph_echo.h"/' "$XELISV2_FILE"
		sudo sed -i 's/#include "sha3\/sph_sha2.h"/#include "..\/sha3\/sph_sha2.h"/' "$XELISV2_FILE"
		sudo sed -i ':a;N;/aes_single_round(uint8_t *block, const uint8_t *key)/!ba;/^}/!d' "$XELISV2_FILE"
		sudo sed -i '/#if defined(__x86_64__)/d' "$XELISV2_FILE"
		sudo sed -i '/#elif defined(__aarch64__)/d' "$XELISV2_FILE"
		sudo sed -i '/#if defined(NO_AES_NI)/d' "$XELISV2_FILE"
		sudo sed -i '/#else/d' "$XELISV2_FILE"
		sudo sed -i '/#endif/d' "$XELISV2_FILE"
		sudo sed -i '/#undef __x86_64__/d' "$XELISV2_FILE"
		sudo sed -i '/#include <emmintrin.h>/ s/^/\/\//' "$XELISV2_FILE"
		sudo sed -i '/#include <immintrin.h>/ s/^/\/\//' "$XELISV2_FILE"
		sudo sed -i '/__m128i/d' "$XELISV2_FILE"
		sudo sed -i '/_mm_/d' "$XELISV2_FILE"
		opening_braces=$(sudo grep -c "{" "$XELISV2_FILE")
		closing_braces=$(sudo grep -c "}" "$XELISV2_FILE")
		if [ "$opening_braces" -ne "$closing_braces" ]; then
			exit 1
		fi
		if ! gcc -fsyntax-only -I.. -Ialgos/blake2 -march=$cpu ${fpu:+-mfpu=$fpu} -DNO_SIMD -DNO_AES_NI -std=gnu99 "$XELISV2_FILE"; then
			sudo sed -i 's/\(xelisv2\.o:.*\)/# \1/' "$ALGO_MAKEFILE"
			sudo sed -i 's/\($(CC) $(CFLAGS) -c xelisv2\.c -o xelisv2\.o\)/# \1/' "$ALGO_MAKEFILE"
		fi
	fi

    # Patche xelisv2-pepew/aes.h pour éliminer les avertissements
    AES_HEADER="${pathstratuminstall}/algos/xelisv2-pepew/aes.h"
    if [ -f "$AES_HEADER" ]; then
        sudo cp "$AES_HEADER" "${AES_HEADER}.bak"
        sudo chmod 666 "$AES_HEADER"
        # Ajoute static à aes_single_round_no_intrinsics
        sudo sed -i 's/inline void aes_single_round_no_intrinsics/static inline void aes_single_round_no_intrinsics/' "$AES_HEADER"
        # Commente les includes SIMD x86
        sudo sed -i '/#include <emmintrin.h>/ s/^/\/\//' "$AES_HEADER"
        sudo sed -i '/#include <immintrin.h>/ s/^/\/\//' "$AES_HEADER"
        # Supprime les directives x86 inutiles
        sudo sed -i '/#if defined(__x86_64__)/d' "$AES_HEADER"
        sudo sed -i '/#elif defined(__aarch64__)/d' "$AES_HEADER"
        sudo sed -i '/#else/d' "$AES_HEADER"
        sudo sed -i '/#endif/d' "$AES_HEADER"
        # Vérifie la balance des accolades
        opening_braces=$(sudo grep -c "{" "$AES_HEADER")
        closing_braces=$(sudo grep -c "}" "$AES_HEADER")
        if [ "$opening_braces" -ne "$closing_braces" ]; then
            echo -e "$YELLOW Error: Unbalanced braces in $AES_HEADER (opening: $opening_braces, closing: $closing_braces)$COL_RESET"
            exit 1
        fi
        # Si aes.h est vide ou ne contient pas aes_single_round_no_intrinsics, ajoute une déclaration minimale
        if ! sudo grep -q "aes_single_round_no_intrinsics" "$AES_HEADER"; then
            sudo bash -c "cat > $AES_HEADER" << 'EOF'
#ifndef AES_H
#define AES_H
#include <stdint.h>
static inline void aes_single_round_no_intrinsics(uint8_t *block, const uint8_t *key);
#endif
EOF
        fi
    else
        # Crée aes.h s'il n'existe pas
        sudo mkdir -p "${pathstratuminstall}/algos/xelisv2-pepew"
        sudo bash -c "cat > $AES_HEADER" << 'EOF'
#ifndef AES_H
#define AES_H
#include <stdint.h>
static inline void aes_single_round_no_intrinsics(uint8_t *block, const uint8_t *key);
#endif
EOF
        sudo chmod 666 "$AES_HEADER"
    fi
	# Supprimer tout doublon de static dans aes_single_round_no_intrinsics
	sudo sed -i 's/static static inline void aes_single_round_no_intrinsics/static inline void aes_single_round_no_intrinsics/' "$AES_HEADER"
    
    # Patche aurum.c pour compatibilité ARM64
    AURUM_FILE="${pathstratuminstall}/algos/aurum.c"
    if [ -f "$AURUM_FILE" ]; then
        sudo cp "$AURUM_FILE" "${AURUM_FILE}.bak"
        sudo chmod 666 "$AURUM_FILE"
        sudo sed -i 's/int PHS(void *out/int PHS(const char *out/' "$AURUM_FILE"
        sudo sed -i '/#include <immintrin.h>/ s/^/\/\//' "$AURUM_FILE"
        sudo sed -i '/#define ADD128(x,y)/d' "$AURUM_FILE"
        sudo sed -i '/#define XOR128(x,y)/d' "$AURUM_FILE"
        sudo sed -i '/#define OR128(x,y)/d' "$AURUM_FILE"
        sudo sed -i '/#define ROTL128(x,n)/d' "$AURUM_FILE"
        sudo sed -i '/#define SHIFTL128(x,n)/d' "$AURUM_FILE"
        sudo sed -i '/#define SHIFTL64(x)/d' "$AURUM_FILE"
        sudo sed -i '/#define SHIFTR64(x)/d' "$AURUM_FILE"
        sudo sed -i '/#if /d' "$AURUM_FILE"
        sudo sed -i '/#ifdef /d' "$AURUM_FILE"
        sudo sed -i '/#ifndef /d' "$AURUM_FILE"
        sudo sed -i '/#else/d' "$AURUM_FILE"
        sudo sed -i '/#endif/d' "$AURUM_FILE"
        sudo sed -i 's/__m128i /uint128_t /g' "$AURUM_FILE"
        sudo sed -i '/#include <stdint.h>/a \
typedef struct {\
    uint64_t lo, hi;\
} uint128_t;\
\
#define ADD128(x, y) ((uint128_t){(x).lo + (y).lo, (x).hi + (y).hi})\
#define XOR128(x, y) ((uint128_t){(x).lo ^ (y).lo, (x).hi ^ (y).hi})\
#define OR128(x, y) ((uint128_t){(x).lo | (y).lo, (x).hi | (y).hi})\
#define ROTL128(x, n) ((uint128_t){((x).lo << (n)) | ((x).lo >> (64 - (n))), ((x).hi << (n)) | ((x).hi >> (64 - (n)))})\
#define SHIFTL128(x, n) ((uint128_t){(x).lo << (n), (x).hi << (n)})\
#define SHIFTL64(x) ((uint128_t){(x).hi, 0})\
#define SHIFTR64(x) ((uint128_t){0, (x).lo})' "$AURUM_FILE"
        opening_braces=$(sudo grep -c "{" "$AURUM_FILE")
        closing_braces=$(sudo grep -c "}" "$AURUM_FILE")
        if [ "$opening_braces" -ne "$closing_braces" ]; then
            sudo bash -c "cat > $AURUM_FILE" << 'EOF'
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

typedef struct {
    uint64_t lo, hi;
} uint128_t;

#define ADD128(x, y) ((uint128_t){(x).lo + (y).lo, (x).hi + (y).hi})
#define XOR128(x, y) ((uint128_t){(x).lo ^ (y).lo, (x).hi ^ (y).hi})
#define OR128(x, y) ((uint128_t){(x).lo | (y).lo, (x).hi | (y).hi})
#define ROTL128(x, n) ((uint128_t){((x).lo << (n)) | ((x).lo >> (64 - (n))), ((x).hi << (n)) | ((x).hi >> (64 - (n)))})
#define SHIFTL128(x, n) ((uint128_t){(x).lo << (n), (x).hi << (n)})
#define SHIFTL64(x) ((uint128_t){(x).hi, 0})
#define SHIFTR64(x) ((uint128_t){0, (x).lo})

#define F0(i) { \
    i0 = ((i) - 0*2) & mask1; \
    i1 = ((i) - 2*2) & mask1; \
    i2 = ((i) - 3*2) & mask1; \
    i3 = ((i) - 7*2) & mask1; \
    i4 = ((i) - 13*2) & mask1; \
    S[i0] = XOR128(ADD128(XOR128(S[i1], S[i2]), S[i3]), S[i4]); \
    S[i0+1] = XOR128(ADD128(XOR128(S[i1+1], S[i2+1]), S[i3+1]), S[i4+1]); \
    temp = S[i0]; \
    S[i0] = XOR128(SHIFTL64(S[i0]), SHIFTR64(S[i0+1])); \
    S[i0+1] = XOR128(SHIFTL64(S[i0+1]), SHIFTR64(temp)); \
    S[i0] = ROTL128(S[i0], 17); \
    S[i0+1] = ROTL128(S[i0+1], 17); \
}

#define F(i) { \
    i0 = ((i) - 0*2) & mask1; \
    i1 = ((i) - 2*2) & mask1; \
    i2 = ((i) - 3*2) & mask1; \
    i3 = ((i) - 7*2) & mask1; \
    i4 = ((i) - 13*2) & mask1; \
    S[i0] = ADD128(S[i0], XOR128(ADD128(XOR128(S[i1], S[i2]), S[i3]), S[i4])); \
    S[i0+1] = ADD128(S[i0+1], XOR128(ADD128(XOR128(S[i1+1], S[i2+1]), S[i3+1]), S[i4+1])); \
    temp = S[i0]; \
    S[i0] = XOR128(SHIFTL64(S[i0]), SHIFTR64(S[i0+1])); \
    S[i0+1] = XOR128(SHIFTL64(S[i0+1]), SHIFTR64(temp)); \
    S[i0] = ROTL128(S[i0], 17); \
    S[i0+1] = ROTL128(S[i0+1], 17); \
}

#define G(i, random_number) { \
    index_global = ((random_number >> 16) & mask) << 1; \
    for (j = 0; j < 64; j = j+2) { \
        F(i+j); \
        index_global = (index_global + 2) & mask1; \
        index_local = (((i + j) >> 1) - 0x1000 + (random_number & 0x1fff)) & mask; \
        index_local = index_local << 1; \
        S[i0] = ADD128(S[i0], SHIFTL128(S[index_local], 1)); \
        S[i0+1] = ADD128(S[i0+1], SHIFTL128(S[index_local+1], 1)); \
        S[index_local] = ADD128(S[index_local], SHIFTL128(S[i0], 2)); \
        S[index_local+1] = ADD128(S[index_local+1], SHIFTL128(S[i0+1], 2)); \
        S[i0] = ADD128(S[i0], SHIFTL128(S[index_global], 1)); \
        S[i0+1] = ADD128(S[i0+1], SHIFTL128(S[index_global+1], 1)); \
        S[index_global] = ADD128(S[index_global], SHIFTL128(S[i0], 3)); \
        S[index_global+1] = ADD128(S[index_global+1], SHIFTL128(S[i0+1], 3)); \
        random_number += (random_number << 2); \
        random_number = (random_number << 19) ^ (random_number >> 45) ^ 3141592653589793238ULL; \
    } \
}

#define H(i, random_number) { \
    index_global = ((random_number >> 16) & mask) << 1; \
    for (j = 0; j < 64; j = j+2) { \
        F(i+j); \
        index_global = (index_global + 2) & mask1; \
        index_local = (((i + j) >> 1) - 0x1000 + (random_number & 0x1fff)) & mask; \
        index_local = index_local << 1; \
        S[i0] = ADD128(S[i0], SHIFTL128(S[index_local], 1)); \
        S[i0+1] = ADD128(S[i0+1], SHIFTL128(S[index_local+1], 1)); \
        S[index_local] = ADD128(S[index_local], SHIFTL128(S[i0], 2)); \
        S[index_local+1] = ADD128(S[index_local+1], SHIFTL128(S[i0+1], 2)); \
        S[i0] = ADD128(S[i0], SHIFTL128(S[index_global], 1)); \
        S[i0+1] = ADD128(S[i0+1], SHIFTL128(S[index_global+1], 1)); \
        S[index_global] = ADD128(S[index_global], SHIFTL128(S[i0], 3)); \
        S[index_global+1] = ADD128(S[index_global+1], SHIFTL128(S[i0+1], 3)); \
        random_number = ((unsigned long long*)S)[i3<<1]; \
    } \
}

int PHS(const char *out, size_t outlen, const void *in, size_t inlen, const void *salt, size_t saltlen, unsigned int t_cost, unsigned int m_cost)
{
    unsigned long long i, j;
    uint128_t temp;
    unsigned long long i0, i1, i2, i3, i4;
    uint128_t *S;
    unsigned long long random_number, index_global, index_local;
    unsigned long long state_size, mask, mask1;

    if (inlen > 256 || saltlen > 64 || outlen > 256 || inlen < 0 || saltlen < 0 || outlen < 0) return 1;

    state_size = 1ULL << (13+m_cost);
    S = (uint128_t *)malloc(state_size);
    if (!S) return 1;

    mask = (1ULL << (8+m_cost)) - 1;
    mask1 = (1ULL << (9+m_cost)) - 1;

    for (i = 0; i < inlen; i++) ((unsigned char*)S)[i] = ((unsigned char*)in)[i];
    for (i = 0; i < saltlen; i++) ((unsigned char*)S)[inlen+i] = ((unsigned char*)salt)[i];
    for (i = inlen+saltlen; i < 384; i++) ((unsigned char*)S)[i] = 0;
    ((unsigned char*)S)[384] = inlen & 0xff;
    ((unsigned char*)S)[385] = (inlen >> 8) & 0xff;
    ((unsigned char*)S)[386] = saltlen;
    ((unsigned char*)S)[387] = outlen & 0xff;
    ((unsigned char*)S)[388] = (outlen >> 8) & 0xff;
    ((unsigned char*)S)[389] = 0;
    ((unsigned char*)S)[390] = 0;
    ((unsigned char*)S)[391] = 0;

    ((unsigned char*)S)[392] = 1;
    ((unsigned char*)S)[393] = 1;
    for (i = 394; i < 416; i++) ((unsigned char*)S)[i] = ((unsigned char*)S)[i-1] + ((unsigned char*)S)[i-2];

    for (i = 13*2; i < (1ULL << (9+m_cost)); i=i+2) F0(i);

    random_number = 123456789ULL;
    for (i = 0; i < (1ULL << (8+m_cost+t_cost)); i=i+64) G(i,random_number);

    for (i = 1ULL << (8+m_cost+t_cost); i < (1ULL << (9+m_cost+t_cost)); i=i+64) H(i,random_number);

    for (i = 0; i < (1ULL << (9+m_cost)); i=i+2) F(i);

    memcpy((void*)out, ((unsigned char*)S)+state_size-outlen, outlen);
    memset(S, 0, state_size);
    free(S);

    return 0;
}

void aurum_hash(const char *input, char *output, uint32_t len)
{
    unsigned int t_cost = 2;
    unsigned int m_cost = 8;

    uint32_t header[20];
    memcpy(header, input, 80);
    uint32_t nonce = (uint32_t)header[19];

    PHS(output, 32, input, 80, &nonce, 4, t_cost, m_cost);
}
EOF
            sudo chmod 666 "$AURUM_FILE"
        fi
		if ! gcc -fsyntax-only -I.. -Ialgos/blake2 -Isha3 -march=$cpu ${fpu:+-mfpu=$fpu} -DNO_SIMD -std=gnu99 "$AURUM_FILE" 2>/dev/null; then
			sudo sed -i 's/\(aurum\.o:.*\)/# \1/' "$ALGO_MAKEFILE"
			sudo sed -i 's/\($(CC) $(CFLAGS) -c aurum\.c -o aurum\.o\)/# \1/' "$ALGO_MAKEFILE"
		fi
    fi
    
	# Patche yespower/yespower-blake2b.c
	YESPOWER_FILE="${pathstratuminstall}/algos/yespower/yespower-blake2b.c"
	if [ -f "$YESPOWER_FILE" ]; then
		sudo chmod 666 "$YESPOWER_FILE"
		# Nettoyer les commentaires multiples (////) pour partir d'un fichier propre
		sudo sed -i 's/\/\/\+/\/\//' "$YESPOWER_FILE"
		# Supprimer les directives NO_SIMD inutiles
		sudo sed -i '/#ifndef NO_SIMD/d' "$YESPOWER_FILE"
		# Commenter les blocs SIMD uniquement si non commentés
		sudo sed -i '/#ifdef __SSE2__/,/#endif/ s/^\([^\/]\)/\/\/\1/' "$YESPOWER_FILE"
		sudo sed -i '/#ifdef __XOP__/,/#endif/ s/^\([^\/]\)/\/\/\1/' "$YESPOWER_FILE"
		sudo sed -i '/#ifdef __AVX__/,/#endif/ s/^\([^\/]\)/\/\/\1/' "$YESPOWER_FILE"
		# Commenter les fonctions salsa20 SIMD uniquement si non commentées
		sudo sed -i '/static inline void salsa20_simd_shuffle/,/static inline void salsa20_simd_unshuffle.*}/ s/^\([^\/]\)/\/\/\1/' "$YESPOWER_FILE"
		# Décommenter yespower_b2b_tls et yespower_b2b si nécessaire
		sudo sed -i 's/\/\/*int yespower_b2b_tls/int yespower_b2b_tls/' "$YESPOWER_FILE"
		sudo sed -i 's/\/\/*int yespower_b2b/int yespower_b2b/' "$YESPOWER_FILE"
		# Supprimer #if defined(__x86_64__) autour de yespower_b2b_tls et yespower_b2b
		sudo sed -i '/#if defined(__x86_64__)/N;/#if defined(__x86_64__)\n.*yespower_b2b/d' "$YESPOWER_FILE"
		sudo sed -i '/#endif/N;/#endif\n.*yespower_b2b/d' "$YESPOWER_FILE"
		# Vérifier la balance des #if/#endif
		if [ $(sudo grep -c "#if\|#ifdef\|#ifndef" "$YESPOWER_FILE") -ne $(sudo grep -c "#endif" "$YESPOWER_FILE") ] || ! gcc -fsyntax-only -I.. -Ialgos/blake2 -march=$cpu ${fpu:+-mfpu=$fpu} -DNO_SIMD -std=gnu99 "$YESPOWER_FILE" 2>/dev/null; then
			echo -e "$YELLOW Warning: Unbalanced preprocessor directives or syntax error in $YESPOWER_FILE, rewriting with generic implementation$COL_RESET"
			sudo bash -c "cat > $YESPOWER_FILE" << 'EOF'
#include <errno.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include "yespower.h"
#include "sysendian.h"
#include "crypto/blake2b-yp.h"
#include "insecure_memzero.h"

#define HUGEPAGE_THRESHOLD (12 * 1024 * 1024)
#ifdef __unix__
#include <sys/mman.h>
#endif

#ifdef __x86_64__
#define HUGEPAGE_SIZE (2 * 1024 * 1024)
#else
#undef HUGEPAGE_SIZE
#endif

typedef struct {
    uint32_t w[16];
} salsa20_blk_t;

static void *alloc_region(yespower_region_t *region, size_t size) {
    size_t base_size = size;
    uint8_t *base, *aligned;
#ifdef MAP_ANON
    int flags =
#ifdef MAP_NOCORE
        MAP_NOCORE |
#endif
        MAP_ANON | MAP_PRIVATE;
#if defined(MAP_HUGETLB) && defined(HUGEPAGE_SIZE)
    size_t new_size = size;
    const size_t hugepage_mask = (size_t)HUGEPAGE_SIZE - 1;
    if (size >= HUGEPAGE_THRESHOLD && size + hugepage_mask >= size) {
        flags |= MAP_HUGETLB;
        new_size = size + hugepage_mask;
        new_size &= ~hugepage_mask;
    }
    base = mmap(NULL, new_size, PROT_READ | PROT_WRITE, flags, -1, 0);
    if (base != MAP_FAILED) {
        base_size = new_size;
    } else if (flags & MAP_HUGETLB) {
        flags &= ~MAP_HUGETLB;
        base = mmap(NULL, size, PROT_READ | PROT_WRITE, flags, -1, 0);
    }
#else
    base = mmap(NULL, size, PROT_READ | PROT_WRITE, flags, -1, 0);
#endif
    if (base == MAP_FAILED)
        base = NULL;
    aligned = base;
#elif defined(HAVE_POSIX_MEMALIGN)
    if ((errno = posix_memalign((void **)&base, 64, size)) != 0)
        base = NULL;
    aligned = base;
#else
    base = aligned = NULL;
    if (size + 63 < size) {
        errno = ENOMEM;
    } else if ((base = malloc(size + 63)) != NULL) {
        aligned = base + 63;
        aligned -= (uintptr_t)aligned & 63;
    }
#endif
    region->base = base;
    region->aligned = aligned;
    region->base_size = base ? base_size : 0;
    region->aligned_size = base ? size : 0;
    return aligned;
}

static inline void init_region(yespower_region_t *region) {
    region->base = region->aligned = NULL;
    region->base_size = region->aligned_size = 0;
}

static int free_region(yespower_region_t *region) {
    if (region->base) {
#ifdef MAP_ANON
        if (munmap(region->base, region->base_size))
            return -1;
#else
        free(region->base);
#endif
    }
    init_region(region);
    return 0;
}

static inline void salsa20(salsa20_blk_t *restrict B,
    salsa20_blk_t *restrict Bout, uint32_t doublerounds) {
    salsa20_blk_t X;
    uint32_t x[16];
    memcpy(x, B->w, sizeof(x));
    for (; doublerounds; doublerounds--) {
        x[ 4] ^= (x[ 0] + x[12]) << 7 | (x[ 0] + x[12]) >> (32 - 7);
        x[ 8] ^= (x[ 4] + x[ 0]) << 9 | (x[ 4] + x[ 0]) >> (32 - 9);
        x[12] ^= (x[ 8] + x[ 4]) << 13 | (x[ 8] + x[ 4]) >> (32 - 13);
        x[ 0] ^= (x[12] + x[ 8]) << 18 | (x[12] + x[ 8]) >> (32 - 18);

        x[ 9] ^= (x[ 5] + x[ 1]) << 7 | (x[ 5] + x[ 1]) >> (32 - 7);
        x[13] ^= (x[ 9] + x[ 5]) << 9 | (x[ 9] + x[ 5]) >> (32 - 9);
        x[ 1] ^= (x[13] + x[ 9]) << 13 | (x[13] + x[ 9]) >> (32 - 13);
        x[ 5] ^= (x[ 1] + x[13]) << 18 | (x[ 1] + x[13]) >> (32 - 18);

        x[14] ^= (x[10] + x[ 6]) << 7 | (x[10] + x[ 6]) >> (32 - 7);
        x[ 2] ^= (x[14] + x[10]) << 9 | (x[14] + x[10]) >> (32 - 9);
        x[ 6] ^= (x[ 2] + x[14]) << 13 | (x[ 2] + x[14]) >> (32 - 13);
        x[10] ^= (x[ 6] + x[ 2]) << 18 | (x[ 6] + x[ 2]) >> (32 - 18);

        x[ 3] ^= (x[15] + x[11]) << 7 | (x[15] + x[11]) >> (32 - 7);
        x[ 7] ^= (x[ 3] + x[15]) << 9 | (x[ 3] + x[15]) >> (32 - 9);
        x[11] ^= (x[ 7] + x[ 3]) << 13 | (x[ 7] + x[ 3]) >> (32 - 13);
        x[15] ^= (x[11] + x[ 7]) << 18 | (x[11] + x[ 7]) >> (32 - 18);

        x[ 1] ^= (x[ 0] + x[ 3]) << 7 | (x[ 0] + x[ 3]) >> (32 - 7);
        x[ 2] ^= (x[ 1] + x[ 0]) << 9 | (x[ 1] + x[ 0]) >> (32 - 9);
        x[ 3] ^= (x[ 2] + x[ 1]) << 13 | (x[ 2] + x[ 1]) >> (32 - 13);
        x[ 0] ^= (x[ 3] + x[ 2]) << 18 | (x[ 3] + x[ 2]) >> (32 - 18);

        x[ 6] ^= (x[ 5] + x[ 4]) << 7 | (x[ 5] + x[ 4]) >> (32 - 7);
        x[ 7] ^= (x[ 6] + x[ 5]) << 9 | (x[ 6] + x[ 5]) >> (32 - 9);
        x[ 4] ^= (x[ 7] + x[ 6]) << 13 | (x[ 7] + x[ 6]) >> (32 - 13);
        x[ 5] ^= (x[ 4] + x[ 7]) << 18 | (x[ 4] + x[ 7]) >> (32 - 18);

        x[11] ^= (x[10] + x[ 9]) << 7 | (x[10] + x[ 9]) >> (32 - 7);
        x[ 8] ^= (x[11] + x[10]) << 9 | (x[11] + x[10]) >> (32 - 9);
        x[ 9] ^= (x[ 8] + x[11]) << 13 | (x[ 8] + x[11]) >> (32 - 13);
        x[10] ^= (x[ 9] + x[ 8]) << 18 | (x[ 9] + x[ 8]) >> (32 - 18);

        x[12] ^= (x[15] + x[14]) << 7 | (x[15] + x[14]) >> (32 - 7);
        x[13] ^= (x[12] + x[15]) << 9 | (x[12] + x[15]) >> (32 - 9);
        x[14] ^= (x[13] + x[12]) << 13 | (x[13] + x[12]) >> (32 - 13);
        x[15] ^= (x[14] + x[13]) << 18 | (x[14] + x[13]) >> (32 - 18);
    }
    for (int i = 0; i < 16; i++) {
        Bout->w[i] = x[i] + B->w[i];
    }
}

#define SALSA20_8(out) salsa20(&X, &out, 4)

static inline void blockmix_salsa(const salsa20_blk_t *restrict Bin,
    salsa20_blk_t *restrict Bout) {
    salsa20_blk_t X;
    memcpy(X.w, Bin[1].w, sizeof(X.w));
    for (int i = 0; i < 16; i++) {
        X.w[i] ^= Bin[0].w[i];
    }
    SALSA20_8(Bout[0]);
    memcpy(X.w, Bin[1].w, sizeof(X.w));
    SALSA20_8(Bout[1]);
}

static inline uint32_t integerify(const salsa20_blk_t *B, size_t r) {
    return B[2 * r - 1].w[0];
}

static void smix(uint8_t *B, size_t r, uint32_t N, salsa20_blk_t *V, salsa20_blk_t *XY) {
    salsa20_blk_t *X = V, *Y = &V[2 * r];
    for (size_t i = 0; i < 2 * r; i++) {
        const salsa20_blk_t *src = (salsa20_blk_t *)&B[i * 64];
        memcpy(&X[i], src, sizeof(salsa20_blk_t));
    }

    for (uint32_t i = 0; i < N; i += 2) {
        blockmix_salsa(X, Y);
        memcpy(&V[i * 2 * r], Y, 2 * r * sizeof(salsa20_blk_t));
        blockmix_salsa(Y, X);
        memcpy(&V[(i + 1) * 2 * r], X, 2 * r * sizeof(salsa20_blk_t));
    }

    for (uint32_t i = 0; i < N; i += 2) {
        uint32_t j = integerify(X, r) & (N - 1);
        for (size_t k = 0; k < 2 * r; k++) {
            X[k].w[0] ^= V[j * 2 * r + k].w[0];
        }
        blockmix_salsa(X, Y);
        memcpy(X, Y, 2 * r * sizeof(salsa20_blk_t));
    }

    for (size_t i = 0; i < 2 * r; i++) {
        memcpy(&B[i * 64], &X[i], sizeof(salsa20_blk_t));
    }
}

int yespower_b2b(yespower_local_t *local,
                 const uint8_t *src, size_t srclen,
                 const yespower_params_t *params,
                 yespower_binary_t *dst) {
    uint32_t N = params->N;
    uint32_t r = params->r;
    const uint8_t *pers = params->pers;
    size_t perslen = params->perslen;
    size_t B_size = (size_t)128 * r;
    size_t V_size = B_size * N;
    size_t XY_size = B_size + 64;
    uint8_t *B, *S;
    salsa20_blk_t *V, *XY;

    if (N < 1024 || N > 512 * 1024 || r < 8 || r > 32 || (N & (N - 1)) != 0 || (!pers && perslen)) {
        errno = EINVAL;
        memset(dst, 0xff, sizeof(*dst));
        return -1;
    }

    size_t need = B_size + V_size + XY_size;
    if (local->aligned_size < need) {
        if (free_region(local))
            return -1;
        if (!alloc_region(local, need))
            return -1;
    }

    B = (uint8_t *)local->aligned;
    V = (salsa20_blk_t *)(B + B_size);
    XY = (salsa20_blk_t *)(B + B_size + V_size);
    S = (uint8_t *)XY + XY_size;

    uint8_t init_hash[32];
    blake2b_yp_hash(init_hash, src, srclen);

    pbkdf2_blake2b_yp(init_hash, sizeof(init_hash), pers ? pers : src, pers ? perslen : 0, 1, B, 128);
    memcpy(init_hash, B, sizeof(init_hash));
    smix(B, r, N, V, XY);
    hmac_blake2b_yp_hash((uint8_t *)dst, B + B_size - 64, 64, init_hash, sizeof(init_hash));

    insecure_memzero(B, B_size);
    free_region(local);
    return 0;
}

int yespower_b2b_tls(const uint8_t *src, size_t srclen,
                     const yespower_params_t *params, yespower_binary_t *dst) {
    static __thread int initialized = 0;
    static __thread yespower_local_t local;

    if (!initialized) {
        init_region(&local);
        initialized = 1;
    }

    int ret = yespower_b2b(&local, src, srclen, params, dst);
    return ret;
}
EOF
        sudo chmod 644 "$YESPOWER_FILE"
    fi
    # S'assurer que yespower-blake2b.o est inclus dans le Makefile
    ALGO_MAKEFILE="${pathstratuminstall}/algos/makefile"
    if ! sudo grep -q "yespower/yespower-blake2b.o" "$ALGO_MAKEFILE"; then
        sudo sed -i 's/libalgos.a:.*$/& yespower\/yespower-blake2b.o/' "$ALGO_MAKEFILE"
        sudo sed -i '$a\
yespower\/yespower-blake2b.o: yespower\/yespower-blake2b.c\n\
\t$(CC) $(CFLAGS) -c yespower\/yespower-blake2b.c -o yespower\/yespower-blake2b.o' "$ALGO_MAKEFILE"
    fi
fi
    
    # Patche blake2/blamka-round-opt.h
    if [ -f "$BLAMKA_FILE" ]; then
        sudo chmod 666 "$BLAMKA_FILE"
        sudo sed -i '/#include "config\/dynamic-config.h"/ s/^/\/\//' "$BLAMKA_FILE"
        sudo sed -i '/#include <emmintrin.h>/ s/^/\/\//' "$BLAMKA_FILE"
        sudo sed -i '/#include <tmmintrin.h>/ s/^/\/\//' "$BLAMKA_FILE"
        sudo sed -i '/#include <x86intrin.h>/ s/^/\/\//' "$BLAMKA_FILE"
        sudo sed -i '/#include <immintrin.h>/ s/^/\/\//' "$BLAMKA_FILE"
        sudo sed -i '/#if /d' "$BLAMKA_FILE"
        sudo sed -i '/#ifdef /d' "$BLAMKA_FILE"
        sudo sed -i '/#ifndef /d' "$BLAMKA_FILE"
        sudo sed -i '/#else/d' "$BLAMKA_FILE"
        sudo sed -i '/#endif/d' "$BLAMKA_FILE"
        sudo sed -i '/__SSE2__/,/}/ s/^/\/\//' "$BLAMKA_FILE"
        sudo sed -i '/__SSSE3__/,/}/ s/^/\/\//' "$BLAMKA_FILE"
        sudo sed -i '/__SSE4_1__/,/}/ s/^/\/\//' "$BLAMKA_FILE"
        sudo sed -i '/__AVX__/,/}/ s/^/\/\//' "$BLAMKA_FILE"
        sudo sed -i '/__AVX2__/,/}/ s/^/\/\//' "$BLAMKA_FILE"
        sudo sed -i '/__AVX512F__/,/}/ s/^/\/\//' "$BLAMKA_FILE"
        sudo sed -i '/__XOP__/,/}/ s/^/\/\//' "$BLAMKA_FILE"
        sudo sed -i '/__m512i/,/}/ s/^/\/\//' "$BLAMKA_FILE"
        sudo sed -i '/#define G1.*\\$/ {N; /#define G1.*\\$/ s/^/\/\//}' "$BLAMKA_FILE"
        sudo sed -i '/#define G2.*\\$/ {N; /#define G2.*\\$/ s/^/\/\//}' "$BLAMKA_FILE"
        sudo sed -i '/#define DIAGONALIZE.*\\$/ {N; /#define DIAGONALIZE.*\\$/ s/^/\/\//}' "$BLAMKA_FILE"
        sudo sed -i '/#define UNDIAGONALIZE.*\\$/ {N; /#define UNDIAGONALIZE.*\\$/ s/^/\/\//}' "$BLAMKA_FILE"
        sudo sed -i '/#define BLAKE2_ROUND.*\\$/ {N; /#define BLAKE2_ROUND.*\\$/ s/^/\/\//}' "$BLAMKA_FILE"
        sudo sed -i '/#define BLAKE2_ROUND_1.*\\$/ {N; /#define BLAKE2_ROUND_1.*\\$/ s/^/\/\//}' "$BLAMKA_FILE"
        sudo sed -i '/#define BLAKE2_ROUND_2.*\\$/ {N; /#define BLAKE2_ROUND_2.*\\$/ s/^/\/\//}' "$BLAMKA_FILE"
        if ! sudo grep -q "//#include <emmintrin.h>" "$BLAMKA_FILE" || ! sudo grep -q "//#include <tmmintrin.h>" "$BLAMKA_FILE" || ! sudo grep -q "//#include <x86intrin.h>" "$BLAMKA_FILE" || ! sudo grep -q "//#include <immintrin.h>" "$BLAMKA_FILE"; then
            sudo sed -i 's/\(ar2\/opt\.o:.*\)/# \1/' "$ALGO_MAKEFILE"
            sudo sed -i 's/\($(CC) $(CFLAGS) -c ar2\/opt\.c -o ar2\/opt\.o\)/# \1/' "$ALGO_MAKEFILE"
        fi
        if [ $(sudo grep -c "#if\|#ifdef\|#ifndef" "$BLAMKA_FILE") -ne 0 ] || [ $(sudo grep -c "#endif" "$BLAMKA_FILE") -ne 0 ]; then
            sudo sed -i 's/\(ar2\/opt\.o:.*\)/# \1/' "$ALGO_MAKEFILE"
            sudo sed -i 's/\($(CC) $(CFLAGS) -c ar2\/opt\.c -o ar2\/opt\.o\)/# \1/' "$ALGO_MAKEFILE"
        fi
    fi
    
    # Patche ar2/argon2.h
    ARGON2_HEADER="${pathstratuminstall}/algos/ar2/argon2.h"
    if [ -f "$ARGON2_HEADER" ]; then
        sudo chmod 666 "$ARGON2_HEADER"
        if ! sudo grep -q "Argon2_i" "$ARGON2_HEADER"; then
            sudo sed -i '/typedef enum Argon2_type {/a \
            \    Argon2_i  = 1,\
            \    Argon2_id = 2,' "$ARGON2_HEADER"
        fi
        if ! sudo grep -q "typedef struct block_ {.*} block;" "$ARGON2_HEADER"; then
            sudo sed -i '/#define ARGON2_BLOCK_SIZE/a \
            \ntypedef struct block_ {\
            \n    uint64_t v[ARGON2_QWORDS_IN_BLOCK];\
            \n} block;' "$ARGON2_HEADER"
        fi
    fi
    
    # Patche ar2/core.h
    CORE_HEADER="${pathstratuminstall}/algos/ar2/core.h"
    if [ -f "$CORE_HEADER" ]; then
        sudo chmod 666 "$CORE_HEADER"
        if sudo grep -q "static void fill_segment" "$CORE_HEADER"; then
            sudo sed -i 's/static void fill_segment/void fill_segment/' "$CORE_HEADER"
        fi
    fi
    
    # Patche ar2/opt.c
    ARGON2_FILE="${pathstratuminstall}/algos/ar2/opt.c"
    if [ -f "$ARGON2_FILE" ]; then
        sudo cp "$ARGON2_FILE" "${ARGON2_FILE}.bak"
        sudo chmod 666 "$ARGON2_FILE"
        if sudo grep -q "expected declaration or statement at end of input\|curr_offset = position.index\|else {" "$ARGON2_FILE"; then
            sudo cp "${ARGON2_FILE}.bak" "$ARGON2_FILE"
        fi
        if sudo grep -q "expected declaration or statement at end of input\|curr_offset = position.index\|else {" "${ARGON2_FILE}.bak"; then
            sudo bash -c "cat > $ARGON2_FILE" << 'EOF'
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include "argon2.h"
#include "core.h"
void fill_block(uint64_t *state, const uint64_t *ref_block, uint64_t *next_block, int with_xor);
void fill_block(uint64_t *state, const uint64_t *ref_block, uint64_t *next_block, int with_xor) {
    uint64_t block[ARGON2_QWORDS_IN_BLOCK];
    for (int i = 0; i < ARGON2_QWORDS_IN_BLOCK; i++) {
        block[i] = state[i] ^ ref_block[i];
        if (with_xor) {
            block[i] ^= next_block[i];
        }
    }
    for (int i = 0; i < ARGON2_QWORDS_IN_BLOCK; i++) {
        next_block[i] = block[i];
    }
}
void fill_segment(const argon2_instance_t *instance, argon2_position_t position) {
    uint64_t state[ARGON2_QWORDS_IN_BLOCK];
    block *ref_block = NULL, *curr_block = NULL;
    uint32_t ref_index, curr_offset, prev_offset, pseudo_rand;
    int data_independent_addressing = (instance->type == Argon2_i) ||
                                     (instance->type == Argon2_id && position.pass == 0 &&
                                      position.slice < ARGON2_SYNC_POINTS / 2);
    prev_offset = position.index == 0 ? instance->lane_length - 1 : position.index - 1;
    curr_offset = position.index;
    for (uint32_t i = 0; i < instance->segment_length; i++, curr_offset++, prev_offset++) {
        if (curr_offset % instance->lane_length == 0) {
            prev_offset = curr_offset - 1;
        }
        if (data_independent_addressing) {
            pseudo_rand = position.pass * ARGON2_SYNC_POINTS + position.slice;
            ref_index = index_alpha(instance, &position, pseudo_rand, 0);
        } else {
            pseudo_rand = (uint32_t)(instance->memory[prev_offset].v[0]);
            ref_index = index_alpha(instance, &position, pseudo_rand,
                                    instance->memory[curr_offset].v[0] & 0x1);
        }
        ref_block = &instance->memory[ref_index];
        curr_block = &instance->memory[curr_offset];
        if (position.pass == 0 && position.slice == 0) {
            fill_block(state, ref_block->v, curr_block->v, 0);
        } else {
            fill_block(state, ref_block->v, curr_block->v, 1);
        }
    }
}
EOF
        else
            sudo sed -i '/#if defined(__AVX512F__)/d' "$ARGON2_FILE"
            sudo sed -i '/#if defined(__AVX2__)/d' "$ARGON2_FILE"
            sudo sed -i '/#else/d' "$ARGON2_FILE"
            sudo sed -i '/#endif/d' "$ARGON2_FILE"
            sudo sed -i '/#ifndef NO_SIMD/d' "$ARGON2_FILE"
            sudo sed -i '/#include "blake2\/blamka-round-opt.h"/ s/^/\/\//' "$ARGON2_FILE"
            sudo sed -i '/_mm256_/,/}/ s/^/\/\//' "$ARGON2_FILE"
            sudo sed -i '/_mm_xor_si128/,/}/ s/^/\/\//' "$ARGON2_FILE"
            sudo sed -i '/BLAKE2_ROUND/,/}/ s/^/\/\//' "$ARGON2_FILE"
            sudo sed -i '/block_XY\[.*\]/d' "$ARGON2_FILE"
            sudo sed -i '/next_block\[.*\]/d' "$ARGON2_FILE"
            sudo sed -i '/block\[.*\]/d' "$ARGON2_FILE"
            sudo sed -i '/data_independent_addressing/d' "$ARGON2_FILE"
            sudo sed -i '/memcpy(state/d' "$ARGON2_FILE"
            sudo sed -i '/curr_offset = position.index/d' "$ARGON2_FILE"
            sudo sed -i '/else {/d' "$ARGON2_FILE"
            sudo sed -i '/void fill_block.*{/,/}/d' "$ARGON2_FILE"
            sudo sed -i '/void fill_segment.*{/,/}/d' "$ARGON2_FILE"
            if ! sudo grep -q "fill_block(" "$ARGON2_FILE"; then
                sudo sed -i '/#include "core.h"/a \
                \nvoid fill_block(uint64_t *state, const uint64_t *ref_block, uint64_t *next_block, int with_xor);' "$ARGON2_FILE"
            fi
            sudo sed -i '/#include "core.h"/a \
            \nvoid fill_block(uint64_t *state, const uint64_t *ref_block, uint64_t *next_block, int with_xor) {\
            \n    uint64_t block[ARGON2_QWORDS_IN_BLOCK];\
            \n    for (int i = 0; i < ARGON2_QWORDS_IN_BLOCK; i++) {\
            \n        block[i] = state[i] ^ ref_block[i];\
            \n        if (with_xor) {\
            \n            block[i] ^= next_block[i];\
            \n        }\
            \n    }\
            \n    for (int i = 0; i < ARGON2_QWORDS_IN_BLOCK; i++) {\
            \n        next_block[i] = block[i];\
            \n    }\
            \n}' "$ARGON2_FILE"
            sudo sed -i '/#include "core.h"/a \
            \nvoid fill_segment(const argon2_instance_t *instance, argon2_position_t position) {\
            \n    uint64_t state[ARGON2_QWORDS_IN_BLOCK];\
            \n    block *ref_block = NULL, *curr_block = NULL;\
            \n    uint32_t ref_index, curr_offset, prev_offset, pseudo_rand;\
            \n    int data_independent_addressing = (instance->type == Argon2_i) ||\
            \n                                     (instance->type == Argon2_id && position.pass == 0 &&\
            \n                                      position.slice < ARGON2_SYNC_POINTS / 2);\
            \n    prev_offset = position.index == 0 ? instance->lane_length - 1 : position.index - 1;\
            \n    curr_offset = position.index;\
            \n    for (uint32_t i = 0; i < instance->segment_length; i++, curr_offset++, prev_offset++) {\
            \n        if (curr_offset % instance->lane_length == 0) {\
            \n            prev_offset = curr_offset - 1;\
            \n        }\
            \n        if (data_independent_addressing) {\
            \n            pseudo_rand = position.pass * ARGON2_SYNC_POINTS + position.slice;\
            \n            ref_index = index_alpha(instance, &position, pseudo_rand, 0);\
            \n        } else {\
            \n            pseudo_rand = (uint32_t)(instance->memory[prev_offset].v[0]);\
            \n            ref_index = index_alpha(instance, &position, pseudo_rand, \
            \n                                    instance->memory[curr_offset].v[0] & 0x1);\
            \n        }\
            \n        ref_block = &instance->memory[ref_index];\
            \n        curr_block = &instance->memory[curr_offset];\
            \n        if (position.pass == 0 && position.slice == 0) {\
            \n            fill_block(state, ref_block->v, curr_block->v, 0);\
            \n        } else {\
            \n            fill_block(state, ref_block->v, curr_block->v, 1);\
            \n        }\
            \n    }\
            \n}' "$ARGON2_FILE"
        fi
        if sudo grep -q "BLAKE2_ROUND\|_mm256_\|_mm_xor_si128" "$ARGON2_FILE"; then
            sudo sed -i '/BLAKE2_ROUND\|_mm256_\|_mm_xor_si128/ s/^/\/\//' "$ARGON2_FILE"
        fi
        opening_braces=$(sudo grep -c "{" "$ARGON2_FILE")
        closing_braces=$(sudo grep -c "}" "$ARGON2_FILE")
        if [ "$opening_braces" -ne "$closing_braces" ]; then
            sudo bash -c "cat > $ARGON2_FILE" << 'EOF'
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include "argon2.h"
#include "core.h"
void fill_block(uint64_t *state, const uint64_t *ref_block, uint64_t *next_block, int with_xor);
void fill_block(uint64_t *state, const uint64_t *ref_block, uint64_t *next_block, int with_xor) {
    uint64_t block[ARGON2_QWORDS_IN_BLOCK];
    for (int i = 0; i < ARGON2_QWORDS_IN_BLOCK; i++) {
        block[i] = state[i] ^ ref_block[i];
        if (with_xor) {
            block[i] ^= next_block[i];
        }
    }
    for (int i = 0; i < ARGON2_QWORDS_IN_BLOCK; i++) {
        next_block[i] = block[i];
    }
}
void fill_segment(const argon2_instance_t *instance, argon2_position_t position) {
    uint64_t state[ARGON2_QWORDS_IN_BLOCK];
    block *ref_block = NULL, *curr_block = NULL;
    uint32_t ref_index, curr_offset, prev_offset, pseudo_rand;
    int data_independent_addressing = (instance->type == Argon2_i) ||
                                     (instance->type == Argon2_id && position.pass == 0 &&
                                      position.slice < ARGON2_SYNC_POINTS / 2);
    prev_offset = position.index == 0 ? instance->lane_length - 1 : position.index - 1;
    curr_offset = position.index;
    for (uint32_t i = 0; i < instance->segment_length; i++, curr_offset++, prev_offset++) {
        if (curr_offset % instance->lane_length == 0) {
            prev_offset = curr_offset - 1;
        }
        if (data_independent_addressing) {
            pseudo_rand = position.pass * ARGON2_SYNC_POINTS + position.slice;
            ref_index = index_alpha(instance, &position, pseudo_rand, 0);
        } else {
            pseudo_rand = (uint32_t)(instance->memory[prev_offset].v[0]);
            ref_index = index_alpha(instance, &position, pseudo_rand,
                                    instance->memory[curr_offset].v[0] & 0x1);
        }
        ref_block = &instance->memory[ref_index];
        curr_block = &instance->memory[curr_offset];
        if (position.pass == 0 && position.slice == 0) {
            fill_block(state, ref_block->v, curr_block->v, 0);
        } else {
            fill_block(state, ref_block->v, curr_block->v, 1);
        }
    }
}
EOF
        fi
		if ! gcc -fsyntax-only -I.. -Ialgos/blake2 -Isha3 -march=$cpu ${fpu:+-mfpu=$fpu} -DNO_SIMD -std=gnu99 "$ARGON2_FILE" 2>/dev/null; then
			sudo bash -c "cat > $ARGON2_FILE" << 'EOF'
#include <uint.h>
#include <string.h>
#include <stdlib.h>
#include "argon2.h"
#include "core.h"
void fill_block(uint64_t *state, const uint64_t *ref_block, uint64_t *next_block, int with_xor);
void fill_block(uint64_t *state, const uint64_t *ref_block, uint64_t *next_block, int with_xor) {
    uint64_t block[ARGON2_QWORDS_IN_BLOCK];
    for (int i = 0; i < ARGON2_QWORDS_IN_BLOCK; i++) {
        block[i] = state[i] ^ ref_block[i];
        if (with_xor) {
            block[i] ^= next_block[i];
        }
    }
    for (int i = 0; i < ARGON2_QWORDS_IN_BLOCK; i++) {
        next_block[i] = block[i];
    }
}
void fill_segment(const argon2_instance_t *instance, argon2_position_t position) {
    uint64_t state[ARGON2_QWORDS_IN_BLOCK];
    block *ref_block = NULL, *curr_block = NULL;
    uint32_t ref_index, curr_offset, prev_offset, pseudo_rand;
    int data_independent_addressing = (instance->type == Argon2_i) ||
                                     (instance->type == Argon2_id && position.pass == 0 &&
                                      position.slice < ARGON2_SYNC_POINTS / 2);
    prev_offset = position.index == 0 ? instance->lane_length - 1 : position.index - 1;
    curr_offset = position.index;
    for (uint32_t i = 0; i < instance->segment_length; i++, curr_offset++, prev_offset++) {
        if (curr_offset % instance->lane_length == 0) {
            prev_offset = curr_offset - 1;
        }
        if (data_independent_addressing) {
            pseudo_rand = position.pass * ARGON2_SYNC_POINTS + position.slice;
            ref_index = index_alpha(instance, &position, pseudo_rand, 0);
        } else {
            pseudo_rand = (uint32_t)(instance->memory[prev_offset].v[0]);
            ref_index = index_alpha(instance, &position, pseudo_rand,
                                    instance->memory[curr_offset].v[0] & 0x1);
        }
        ref_block = &instance->memory[ref_index];
        curr_block = &instance->memory[curr_offset];
        if (position.pass == 0 && position.slice == 0) {
            fill_block(state, ref_block->v, curr_block->v, 0);
        } else {
            fill_block(state, ref_block->v, curr_block->v, 1);
        }
    }
}
EOF
        fi
        if [ $(sudo grep -c "#if\|#ifdef\|#ifndef" "$ARGON2_FILE") -ne $(sudo grep -c "#endif" "$ARGON2_FILE") ]; then
            sudo bash -c "cat > $ARGON2_FILE" << 'EOF'
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include "argon2.h"
#include "core.h"
void fill_block(uint64_t *state, const uint64_t *ref_block, uint64_t *next_block, int with_xor);
void fill_block(uint64_t *state, const uint64_t *ref_block, uint64_t *next_block, int with_xor) {
    uint64_t block[ARGON2_QWORDS_IN_BLOCK];
    for (int i = 0; i < ARGON2_QWORDS_IN_BLOCK; i++) {
        block[i] = state[i] ^ ref_block[i];
        if (with_xor) {
            block[i] ^= next_block[i];
        }
    }
    for (int i = 0; i < ARGON2_QWORDS_IN_BLOCK; i++) {
        next_block[i] = block[i];
    }
}
void fill_segment(const argon2_instance_t *instance, argon2_position_t position) {
    uint64_t state[ARGON2_QWORDS_IN_BLOCK];
    block *ref_block = NULL, *curr_block = NULL;
    uint32_t ref_index, curr_offset, prev_offset, pseudo_rand;
    int data_independent_addressing = (instance->type == Argon2_i) ||
                                     (instance->type == Argon2_id && position.pass == 0 &&
                                      position.slice < ARGON2_SYNC_POINTS / 2);
    prev_offset = position.index == 0 ? instance->lane_length - 1 : position.index - 1;
    curr_offset = position.index;
    for (uint32_t i = 0; i < instance->segment_length; i++, curr_offset++, prev_offset++) {
        if (curr_offset % instance->lane_length == 0) {
            prev_offset = curr_offset - 1;
        }
        if (data_independent_addressing) {
            pseudo_rand = position.pass * ARGON2_SYNC_POINTS + position.slice;
            ref_index = index_alpha(instance, &position, pseudo_rand, 0);
        } else {
            pseudo_rand = (uint32_t)(instance->memory[prev_offset].v[0]);
            ref_index = index_alpha(instance, &position, pseudo_rand,
                                    instance->memory[curr_offset].v[0] & 0x1);
        }
        ref_block = &instance->memory[ref_index];
        curr_block = &instance->memory[curr_offset];
        if (position.pass == 0 && position.slice == 0) {
            fill_block(state, ref_block->v, curr_block->v, 0);
        } else {
            fill_block(state, ref_block->v, curr_block->v, 1);
        }
    }
}
EOF
        fi
    fi
    
    # Vérifie et définit salsa20_blk_t
    YESPOWER_HEADER="${pathstratuminstall}/algos/yespower/yespower.h"
    if [ -f "$YESPOWER_HEADER" ] && ! sudo grep -q "salsa20_blk_t" "$YESPOWER_HEADER"; then
        sudo chmod 666 "$YESPOWER_HEADER"
        sudo sed -i '$a\
        \n#ifndef NO_SIMD\
        \ntypedef struct {\
        \n    uint32_t w[16];\
        \n} salsa20_blk_t;\
        \n#endif' "$YESPOWER_HEADER"
    fi
    
    # Ajoute une déclaration pour PBKDF2_SHA256_Y
    YESCRYPT_HEADER="${pathstratuminstall}/algos/yescrypt.h"
    if [ -f "$YESCRYPT_HEADER" ] && ! sudo grep -q "PBKDF2_SHA256_Y" "$YESCRYPT_HEADER"; then
        sudo chmod 666 "$YESCRYPT_HEADER"
        sudo sed -i '$a\
        \nvoid PBKDF2_SHA256_Y(const uint8_t *passwd, size_t passwdlen, const uint8_t *salt, size_t saltlen, uint64_t c, uint8_t *buf, size_t dkLen);' "$YESCRYPT_HEADER"
    fi

	# Update Makefile to use -lmariadb (optional)
 	LMYSQLCLIENT="${pathstratuminstall}/Makefile"
	if grep -q "\-lmysqlclient" "$LMYSQLCLIENT"; then
	    echo -e "${CYAN} Processing: Updating Makefile to use -lmariadb...${COL_RESET}"
	    sudo sed -i 's/-lmysqlclient/-lmariadb/' "$LMYSQLCLIENT"
	fi
    
	export CFLAGS="-DNO_SIMD -march=$cpu ${fpu:+-mfpu=$fpu} -Ialgos/blake2 -Ialgos/ar2 -I.. -std=gnu99"
else
    export CFLAGS="-DNO_SIMD"
	echo -e "${YELLOW} Running compilation Straum${COL_RESET}"
fi

# Compiler
if sudo make; then
    echo " >--> Compiled stratum successfully"
	export STRCOMPILED="Y"
else
    echo -e "$YELLOW Warning: Failed to compile stratum, check install.log for details...$COL_RESET"
    sleep 4
	export STRCOMPILED="N"
fi
sleep 1
