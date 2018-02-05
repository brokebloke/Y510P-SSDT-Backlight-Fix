# Y510P-SSDT-Backlight-Fix
This is my version of a backlight fix using AppleBacklight and AppleBacklightInject kexts compiled with various resources found online utilizing an SSDT hack from this repo https://github.com/intruder16/Y510p-OS-X-Clover-Hotpatch.
This also works with Lenovo Y510P devices pre 10.12.4 with included IntelBacklight.kext parameters (although unnecessary). Keys use the Voodoo PS2 kext file and wont work unless edited specifically.

# Install
Simply copy and place the SSDT-HACK.aml file to EFI/CLOVER/ACPI/patched
Copy the modified AppleBacklightInjector.kext by using the following command

**sudo cp -R AppleBacklightInjector.kext /Library/Extensions/**

And then initializing the kextcache with command

**sudo kextcache -i /**

Note: kext-dev-mode must be enabled.

# Credits

https://www.tonymacx86.com/threads/guide-laptop-backlight-control-using-applebacklightinjector-kext.218222/
https://github.com/intruder16/Y510p-OS-X-Clover-Hotpatch



