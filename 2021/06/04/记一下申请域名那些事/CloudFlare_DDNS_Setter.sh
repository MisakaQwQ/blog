#!/bin/bash
Green_font="\033[32m" && Red_font="\033[31m" && Font_suffix="\033[0m"
Info="${Green_font}[Info]${Font_suffix}"
Error="${Red_font}[Error]${Font_suffix}"
echo -e "${Green_font}
${Font_suffix}"

check_root(){
        [[ "`id -u`" != "0" ]] && echo -e "${Error} must be root user !" && exit 1
}

directory(){
        [[ ! -d /root/CloudFlare_DDNS ]] && echo -e "${Error} can not found config directory, please check !" && exit 1
        cd /root/CloudFlare_DDNS
}

define(){
        [[ ! -f config.conf ]] && echo -e "${Error} can not found config file, please check !" && exit 1

        email=`cat config.conf | grep "email" | awk -F "=" '{print $NF}'`
        zone_id=`cat config.conf | grep "zone_id" | awk -F "=" '{print $NF}'`
        api_key=`cat config.conf | grep "api_key" | awk -F "=" '{print $NF}'`

        record_id=`cat config.conf | grep "record_id" | awk -F "=" '{print $NF}'`
        domain=`cat config.conf | grep "domain" | awk -F "=" '{print $NF}'`
        ttl=`cat config.conf | grep "ttl" | awk -F "=" '{print $NF}'`

        dynamic_ip=`curl ip.sb`
}

choose_service(){
        if [[ -z "$1" ]]; then
                echo -e "${Info} if you want a automatic ddns, firstly you should get record_id"
                echo -e "${Info} alternatively you can use this script to create a A record and get its id"
                echo -e "${Info} now select required service:\n1.get domain record_id\n2.create a new domain A record"
                read -p "(input 1 or 2 to select):" service
                while [[ ! "${service}" =~ ^[1-2]$ ]]
                do
                        echo -e "${Error} invalid input !"
                        read -p "(input 1 or 2 to select):" service
                done
                [[ "${service}" = "1" ]] && get_record_id
                [[ "${service}" = "2" ]] && create_record

        elif [[ "$1" == "--ddns" ]]; then
                echo -e "${Info} now will start automatically ddns record updating service"
                old_ip=`head -n +1 /root/CloudFlare_DDNS/ip`
                echo -e "${old_ip}"
                if [[ $old_ip != $dynamic_ip ]]; then
                        echo -e "ip has changed, updating"
                        update_record
                        echo "$dynamic_ip" > /root/CloudFlare_DDNS/ip
                        echo -e "${Info} updated ip"
                fi
        else
                echo -e "${Error} invalid input !" && exit 1
        fi
}

get_record_id(){
curl -X GET "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records" \
         -H "X-Auth-Email: ${email}" \
         -H "X-Auth-Key: ${api_key}" \
         -H "Content-Type: application/json"
}

update_record(){
curl -X PUT "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records/${record_id}" \
         -H "X-Auth-Email: ${email}" \
         -H "X-Auth-Key: ${api_key}" \
         -H "Content-Type: application/json" \
         --data '{"type":"A", "name":"'${domain}'", "content":"'${dynamic_ip}'", "ttl":'${ttl}', "proxied":false}'
}

create_record(){
curl -X POST "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records" \
         -H "X-Auth-Email: ${email}" \
         -H "X-Auth-Key: ${api_key}" \
         -H "Content-Type: application/json" \
         --data '{"type":"A", "name":"'${domain}'", "content":"'${dynamic_ip}'", "ttl":'${ttl}', "proxied":false}'
}



check_root
directory
define
choose_service $1