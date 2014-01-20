#/bin/bash
#This script gets addressbalance from the dogechain.info API and multiplies it by
#the current BTC value on Cryptsy and the BTC/USD exchange rate on bitcoinaverage.com
DOGEADDRESS="D000000000000000000000000000000000"
pushoverNotificationsEnabled="false"
POTOKEN="000000000000000000000000000000"
POUSER="000000000000000000000000000000"
POSOUND="intermission"
dogeBalance=$(curl -s https://dogechain.info/chain/CHAIN/q/addressbalance/$DOGEADDRESS)
echo "DOGE balance: $dogeBalance"
#This will keep trying till it gets a valid response from Cryptsy API
requestFail="true"
while [ $requestFail = "true" ]; do
	bitcoinPriceResult=$(curl -s http://pubapi.cryptsy.com/api.php?method=singlemarketdata\&marketid=132)
	if [ -n "$(echo $bitcoinPriceResult | grep "502 Bad Gateway")" ] ; then
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
usdPriceResult=$(curl -s https://api.bitcoinaverage.com/ticker/global/USD/)
usdPrice=$(echo $usdPriceResult | grep -oP '(?<=\"last\": ).*' | sed 's/,.*//')
usdValue=$(printf "%.2f\n" $(echo "$bitcoinValue * $usdPrice" | bc))
echo "Value of your DOGE in USD: $usdValue"
if [ "$pushoverNotificationsEnabled" = "true" ]; then
	echo "Sending notification to Pushover..."
	curl -s -F "token=$POTOKEN" -F "user=$POUSER" -F "title=Current dogecoin value" -F "message=Balance: $dogeBalance DOGE - Value in BTC: $bitcoinPrice BTC - Value in USD: \$$usdValue" -F "sound=$POSOUND" https://api.pushover.net/1/messages.json > /dev/null
fi
echo "Done"
exit 0
