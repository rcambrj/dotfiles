# Android USB Tethering

For my secondary uplink I use an Android phone.

I'd rather use an LTE router, but I do this because LTE providers where I live continue to make it difficult to connect routers to their service. I live in the EU, where it's illegal for service providers to block compliant devices, but that legislation hasn't stopped providers from hiding behind the vague "not supported" excuse, where a device might just stop working from one day to the next - guess how I know. This allows me to use LTE services which don't officially support routers, because although the purpose is the same, the Android phone looks like a phone to the LTE provider.

Hall of Shame (providers who's SIMs don't work in my LTE router):

* 50plusmobiel NL
* lebara NL

However, Android also isn't intended to be an always-on machine with predictable settings. On Android 4 the `USB tethering` becomes disabled and must be enabled upon connecting the USB cable, and on Android 13 the `OTG connection` and `Ethernet tethering` settings both become disabled after 10 minutes.

To fix that, there are automation flows in this directory. For Android 4 a LlamaLab [Automate] flow and for Android 13 a [Tasker] task.

[Automate]: https://llamalab.com/automate/
[Tasker]: https://tasker.joaoapps.com/