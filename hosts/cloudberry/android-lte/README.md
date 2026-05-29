# Android USB Tethering

For my secondary uplink I use an Android phone.

## Expectations

The secondary WAN connection needs to be _just good enough_. That is, I'm not expecting to play FPS games, download multi-gigabyte files or stream videos all day long. Factors:

- unpredictable 4G connection
- expensive data transfer (read: limited data transfer)
- triple NAT: almost all LTE providers here use CGNAT, plus the home router, and Android phone don't do bridge mode

## Batteries

The batteries must be removed from an Android phone in order to use them in this way, because lithium batteries will inevitably eventually swell into spicy pillows.

## IP ranges

Previously, Android would use 192.168.42.0/24 or 192.168.43.0/24, depending on the tethering technology. Since Android 11 (API 30), any kind of tethering creates a private network for clients in the 192.168.*.0/24 range. This means that one cannot reliably use any 192.168.*.* subnet nearby, if one wants to route subnets correctly. So private subnets are limited to 10.0.0.0/8 or 172.168.0.0/16.

## Software quirks

Android also isn't intended to be an always-on machine with predictable settings, as such, one must use tools like [Tasker] or Llamalab [Automate] to constantly monitor and fix settings which become automatically toggled by the system.

* on Android 4 `USB tethering` becomes disabled and must be enabled upon connecting the USB cable. The LlamaLab [Automate] flow is stable on a `Samsung S4 Mini i9195`, I used this for many years. I connected the battery terminals to a 4.5V power supply (the phone will not boot without a voltage across the battery terminals). Abandoned because unfortunately this phone doesn't boot until the power button is held for a few seconds.
* on Android 13 `Ethernet tethering` becomes disabled, because the `OTG connection` becomes disabled after 10 minutes, even with activity. I tried to get it to remain active, but failed. A [Tasker] task represents my attempt.
* on Android 13 `USB tethering` becomes disabled and must be enabled upon connecting the USB cable, just like on Android 4. The Llamalab [Automate] flow does that and is stable on a `realme 8 4G`. I connected the battery terminals to a 4.5V power supply, and the phone boots as soon as power is presented on the USB connector. **This phone and flow is currently in use**.

## Why an Android phone

I'd rather use an LTE router, but LTE providers where I live continue to make it difficult to connect routers to their service. I live in the EU, where it's illegal for service providers to block compliant devices, but that legislation hasn't stopped providers from hiding behind the vague "not supported" excuse, where a device might just stop working from one day to the next - guess how I know. Using an Android phone falls under these providers' "supported" umbrella, whilst serving as a _good enough_ hop. /rant

Hall of Shame (providers who's SIMs don't work in my LTE router):

* 50plusmobiel NL
* lebara NL

[Automate]: https://llamalab.com/automate/
[Tasker]: https://tasker.joaoapps.com/
