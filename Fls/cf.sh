#!/bin/bash
apt install jq curl -y
if [[ ! -d /etc/github ]]; then  # Memeriksa apakah folder /etc/github tidak ada
    mkdir -p /etc/github         # Membuat folder /etc/github jika tidak ada
fi

if [[ ! -e /etc/github/cf ]]; then  # Memeriksa apakah file /etc/github/cf tidak ada
    curl -s https://pastebin.com/raw/Bigu4aKU > /etc/github/cf  # Mengunduh dan membuat file cf jika belum ada
fi

DO=$(cat /etc/xray/domain | cut -d "." -f2-)
SUB=$(cat /etc/xray/domain | cut -d "." -f1)


if [[ -z "$DO" ]]; then
    DO="rahmatstore.cloud"
fi

# Memeriksa apakah SUB kosong, jika kosong maka isi dengan 4 karakter acak alfanumerik
if [[ -z "$SUB" ]]; then
    SUB=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 4)
fi

IP=$(curl -sS ipv4.icanhazip.com)
SUB_DOMAIN=${SUB}.${DO}
NS_DOMAIN=*.${SUB_DOMAIN}
echo "$SUB_DOMAIN" > /etc/xray/domain
echo "$SUB_DOMAIN" > /root/domain
CF_KEY=$(cat /etc/github/cf)
set -euo pipefail
echo "Pointing Domain for $SUB_DOMAIN..."
ZONE=$(
		curl -sLX GET "https://api.cloudflare.com/client/v4/zones?name=${DO}&status=active" \
		-H "Authorization: Bearer ${CF_KEY}" \
		-H "Content-Type: application/json" | jq -r .result[0].id
	)

	RECORD=$(
		curl -sLX GET "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records?name=${SUB_DOMAIN}" \
		-H "Authorization: Bearer ${CF_KEY}" \
		-H "Content-Type: application/json" | jq -r .result[0].id
	)

		RECORD1=$(
		curl -sLX GET "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records?name=${NS_DOMAIN}" \
		-H "Authorization: Bearer ${CF_KEY}" \
		-H "Content-Type: application/json" | jq -r .result[0].id
	)

	if [[ "${#RECORD}" -le 10 ]]; then
		RECORD=$(
			curl -sLX POST "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records" \
			-H "Authorization: Bearer ${CF_KEY}" \
			-H "Content-Type: application/json" \
			--data '{"type":"A","name":"'${SUB_DOMAIN}'","content":"'${IP}'","proxied":false}' | jq -r .result.id
		)
	else
		RESULT=$(
		curl -sLX PUT "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records/${RECORD}" \
		-H "Authorization: Bearer ${CF_KEY}" \
		-H "Content-Type: application/json" \
		--data '{"type":"A","name":"'${SUB_DOMAIN}'","content":"'${IP}'","proxied":false}'
	)
	fi
		
	if [[ "${#RECORD1}" -le 10 ]]; then
		RECORD2=$(
			curl -sLX POST "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records" \
			-H "Authorization: Bearer ${CF_KEY}" \
			-H "Content-Type: application/json" \
			--data '{"type":"A","name":"'${NS_DOMAIN}'","content":"'${IP}'","proxied":true}' | jq -r .result.id
		)
	else

	RESULT2=$(
		curl -sLX PUT "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records/${RECORD1}" \
		-H "Authorization: Bearer ${CF_KEY}" \
		-H "Content-Type: application/json" \
		--data '{"type":"A","name":"'${NS_DOMAIN}'","content":"'${IP}'","proxied":true}'
	)	
	fi
sleep 1
clear
