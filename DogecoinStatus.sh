#/bin/bash
#This script gets addressbalance from the dogechain.info API and multiplies it by
#the current BTC value on Cryptsy and the BTC/USD exchange rate on MTGOX
DOGEADDRESS="D000000000000000000000000000000000"
pushoverNotificationsEnabled="false"
#Fill these out if you are using Pushover notifications
POTOKEN="000000000000000000000000000000"
POUSER="000000000000000000000000000000"
POSOUND="intermission"
dogeBalance=$(curl -s https://dogechain.info/chain/CHAIN/q/addressbalance/$DOGEADDRESS)
echo "DOGE balance: $dogeBalance"
#This will keep trying till it gets a valid response from Cryptsy API
requestFail="true"
while [ $requestFail = "true" ]; do
	bitcoinPriceResult=$(curl -s http://pubapi.cryptsy.com/api.php?method=singlemarketdata\&marketid=132)
	if [ -n "$(echo $bitcoinPriceResult | grep "502 Bad Gateway")" ] || [ -n "$(echo $bitcoinPriceResult | grep "\{\"success\":1,\"return\":0")" ] || [ -n "$(echo $bitcoinPriceResult | grep "\{\"success\":1,\"return\":false")" ]; then
		echo "Failed to grab latest market values"
		sleep 2
		echo "Trying again..."
	else
		requestFail="false"
		echo "Grabbed latest market values..."
	fi
done
bitcoinPrice=$(echo $bitcoinPriceResult | grep -oP '(?<=\"price\":\").*' | sed 's/\".*//')
echo "Latest trade in BTC: $bitcoinPrice"
bitcoinValue=$(echo "$dogeBalance * $bitcoinPrice" | bc)
echo "Value of your DOGE in BTC: $bitcoinValue"
usdPrice=$(curl -s https://www.bitstamp.net/api/ticker/ | grep -oP '(?<=\"last\":\ \").*' | sed 's/\",.*//')
usdValue=$(echo "$bitcoinValue * $usdPrice" | bc)
echo "Value of your DOGE in USD: $usdValue"
echo "$(date +"%Y-%m-%d %T") - DOGE balance: $dogeBalance - Latest trade in BTC: $bitcoinPrice - Value of your DOGE in BTC: $bitcoinValue - Value of your DOGE in USD: \$$usdValue" >> DogecoinStatus.log
if [ "$pushoverNotificationsEnabled" = "true" ]; then
	echo "Sending notification to Pushover..."
	curl -s -F "token=$POTOKEN" -F "user=$POUSER" -F "title=Dogecoin value" -F "message=Balance: $dogeBalance DOGE -- $bitcoinValue BTC -- \$$usdValue" -F "sound=$POSOUND" https://api.pushover.net/1/messages.json > /dev/null
fi
echo "Done"
exit 0
