# Android USB Tethering

For my secondary uplink I use a cheap Android phone connected via USB Tethering.

I'd rather use an LTE router, but I do this because LTE providers where I live continue to make it difficult to connect routers to their service. I live in the EU, where it's illegal for service providers to block compliant devices, but that legislation hasn't stopped providers from hiding behind the vague "not supported" excuse, where a device might just stop working from one day to the next - guess how I know. This allows me to use LTE services which don't officially support routers, because although the purpose is the same, the Android phone looks like a phone to the LTE provider.

Hall of Shame (providers who's SIMs don't work in my LTE router):

* 50plusmobiel NL
* lebara NL

However, it's not possible to permanently enable USB Tethering on this phone - it gets disabled whenever the USB cable is disconnected or the phone is restarted. To fix that, I made an [Automate] Flow which automatically enables the setting as soon as the USB connection is detected. Just import the .flo file into [Automate] and start it.

[Automate]: https://llamalab.com/automate/