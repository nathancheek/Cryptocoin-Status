#/bin/bash
#This script gets the address balance from the blockchain.info API and multiplies it by
#the BTC/USD exchange rate from MTGOX
BTCADDRESS="100000000000000000000000000000"
pushoverNotificationsEnabled="false"
#Fill these out if you are using Pushover notifications
POTOKEN="000000000000000000000000000000"
POUSER="000000000000000000000000000000"
POSOUND="intermission"
btcBalance=$(curl -s https://blockchain.info/rawaddr/$BTCADDRESS | grep -oP '(?<=\"final_balance\":).*' | sed 's/,.*//')
btcBalance=$(echo "${btcBalance:0:-8}.${btcBalance: -8}")
echo "BTC balance: $btcBalance"
usdPrice=$(curl -s https://www.bitstamp.net/api/ticker/ | grep -oP '(?<=\"last\":\ \").*' | sed 's/\",.*//')
echo "Latest trade in USD: $usdPrice"
usdValue=$(printf "%.2f\n" $(echo "$btcBalance * $usdPrice" | bc))
echo "Value of your BTC in USD: $usdValue"
echo "$(date +"%Y-%m-%d %T") - BTC balance: $btcBalance - Latest trade in USD: $usdPrice - Value of your BTC in USD: \$$usdValue" >> ~/BitcoinStatus.log
if [ "$pushoverNotificationsEnabled" = "true" ]; then
	echo "Sending notification to Pushover..."
	curl -s -F "token=$POTOKEN" -F "user=$POUSER" -F "title=Current bitcoin value" -F "message=Balance: $btcBalance BTC - Exchange rate: \$$usdPrice - Value in USD: \$$usdValue" -F "sound=$POSOUND" https://api.pushover.net/1/messages.json > /dev/null
fi
echo "Done"