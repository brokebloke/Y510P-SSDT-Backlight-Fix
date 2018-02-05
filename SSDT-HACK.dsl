// Creating one All-In-One SSDT for hacks, no need to use SortedOrder
// There are of course seperate SSDT's in "seperate" folder NOTE : Use SortedOrder with that.

// Created by : Intruder16
// Credits : RehabMan

DefinitionBlock ("", "SSDT", 2, "Y510p", "hack", 0)
{
    External(_SB.PCI0, DeviceObj)
    External(_SB.PCI0.LPCB, DeviceObj)

    // All _OSI calls in DSDT are routed to XOSI...
    // XOSI simulates "Windows 2012" (which is Windows 8)
    // Note: According to ACPI spec, _OSI("Windows") must also return true
    // Also, it should return true for all previous versions of Windows.
    Method(XOSI, 1)
    {
        Store(Package()
        {
            "Windows",              // generic Windows query
            "Windows 2001",         // Windows XP
            "Windows 2001 SP2",     // Windows XP SP2
            //"Windows 2001.1",     // Windows Server 2003
            //"Windows 2001.1 SP1", // Windows Server 2003 SP1
            "Windows 2006",         // Windows Vista
            "Windows 2006 SP1",     // Windows Vista SP1
            //"Windows 2006.1",     // Windows Server 2008
            "Windows 2009",         // Windows 7/Windows Server 2008 R2
            "Windows 2012",         // Windows 8/Windows Server 2012
            //"Windows 2013",       // Windows 8.1/Windows Server 2012 R2
            //"Windows 2015",       // Windows 10/Windows Server TP
        }, Local0)
        Return (Ones != Match(Local0, MEQ, Arg0, MTR, 0, 0))
    }

//
// USB related
//

    // Disabling XSEL
    
    External(_SB.PCI0.XHC, DeviceObj)

    // In DSDT, native XSEL is renamed ZSEL
    // As a result, calls to it land here.
    Method(_SB.PCI0.XHC.XSEL)
    {
        // do nothing
    }
    
    // For solving instant wake by hooking GPRW
    
    Method(GPRW, 2)
    {
        If (0x6d == Arg0) { Return (Package() { 0x6d, Zero, }) }
        If (0x0d == Arg0) { Return (Package() { 0x0d, Zero, }) }
        External(\XPRW, MethodObj)
        Return (XPRW(Arg0, Arg1))
    }

    // USBInjectAll configuration/override
    
    Device(UIAC)
    {
        Name(_HID, "UIA00000")

        Name(RMCF, Package()
        {
            "8086_8c31", Package()
            {
                //"port-count", Buffer() { 21, 0, 0, 0 },
                "ports", Package()
                {
                    "HS01", Package()    // Camera
                    {
                        "UsbConnector", 255,
                        "port", Buffer() { 0x01, 0, 0, 0 },
                    },
                    "HS02", Package()    // USB 2.0 right
                    {
                        "UsbConnector", 0,
                        "port", Buffer() { 0x02, 0, 0, 0 },
                    },
                    "HS03", Package()    // HS component of USB 3.0 near left
                    {
                        "UsbConnector", 3,
                        "port", Buffer() { 0x03, 0, 0, 0 },
                    },
                    "HS04", Package()    // HS component of USB 3.0 far left
                    {
                        "UsbConnector", 3,
                        "port", Buffer() { 0x04, 0, 0, 0 },
                    },
                    "HS07", Package()    // Bluetooth 
                    {
                        "UsbConnector", 255,
                        "port", Buffer() { 0x07, 0, 0, 0 },
                    },
                    "SSP2", Package()    // USB 3.0 near left
                    {
                        "UsbConnector", 3,
                        "port", Buffer() { 0x11, 0, 0, 0 },
                    },
                    "SSP3", Package()    // USB 3.0 far left
                    {
                        "UsbConnector", 3,
                        "port", Buffer() { 0x12, 0, 0, 0 },
                    },
                    "SSP4", Package()    // Card Reader
                    {
                        "UsbConnector", 255,
                        "port", Buffer() { 0x13, 0, 0, 0 },
                    },
                },
            },
        })
    }
    
    // Disabling EHCI #1 (and EHCI #2)

    External(_SB.PCI0.EH01, DeviceObj)
    External(_SB.PCI0.EH02, DeviceObj)
    
    Scope(_SB.PCI0)
    {
        // registers needed for disabling EHC#1
        Scope(EH01)
        {
            OperationRegion(PSTS, PCI_Config, 0x54, 2)
            Field(PSTS, WordAcc, NoLock, Preserve)
            {
                PSTE, 2  // bits 2:0 are power state
            }
        }
        // registers needed for disabling EHC#1
        Scope(EH02)
        {
            OperationRegion(PSTS, PCI_Config, 0x54, 2)
            Field(PSTS, WordAcc, NoLock, Preserve)
            {
                PSTE, 2  // bits 2:0 are power state
            }
        }
        Scope(LPCB)
        {
            OperationRegion(RMLP, PCI_Config, 0xF0, 4)
            Field(RMLP, DWordAcc, NoLock, Preserve)
            {
                RCB1, 32, // Root Complex Base Address
            }
            // address is in bits 31:14
            OperationRegion(FDM1, SystemMemory, (RCB1 & Not((1<<14)-1)) + 0x3418, 4)
            Field(FDM1, DWordAcc, NoLock, Preserve)
            {
                ,13,    // skip first 13 bits
                FDE2,1, // should be bit 13 (0-based) (FD EHCI#2)
                ,1,
                FDE1,1, // should be bit 15 (0-based) (FD EHCI#1)
            }
        }
        
        Device(RMD1)
        {
            //Name(_ADR, 0)
            Name(_HID, "RMD10000")
            Method(_INI)
            {
                // disable EHCI#1
                // put EHCI#1 in D3hot (sleep mode)
                ^^EH01.PSTE = 3
                // disable EHCI#1 PCI space
                ^^LPCB.FDE1 = 1

                // disable EHCI#2
                // put EHCI#2 in D3hot (sleep mode)
                ^^EH02.PSTE = 3
                // disable EHCI#2 PCI space
                ^^LPCB.FDE2 = 1
            }
        }
    }

    // Inject properties for XHC
    
    External(_SB.PCI0.XHC, DeviceObj)
    
    If (CondRefOf(_SB.PCI0.XHC))
    {
        Method(_SB.PCI0.XHC._DSM, 4)
        {
            If (!Arg2) { Return (Buffer() { 0x03 } ) }
            Local0 = Package()
            {
                "RM,pr2-force", Buffer() { 0, 0, 0, 0 },
                "subsystem-id", Buffer() { 0x70, 0x72, 0x00, 0x00 },
                "subsystem-vendor-id", Buffer() { 0x86, 0x80, 0x00, 0x00 },
                "AAPL,current-available", Buffer() { 0x34, 0x08, 0, 0 },
                "AAPL,current-extra", Buffer() { 0x98, 0x08, 0, 0, },
                "AAPL,current-extra-in-sleep", Buffer() { 0x40, 0x06, 0, 0, },
                "AAPL,max-port-current-in-sleep", Buffer() { 0x34, 0x08, 0, 0 },
            }
            // Force USB2 on XHC if EHCI is disabled
            
            If (CondRefOf(\_SB.PCI0.RMD2))
            {
                CreateDWordField(DerefOf(Local0[1]), Zero, PR2F)
                PR2F = 0x3fff
            }
            Return(Local0)
        }
    }

//
// Backlight control
//
#define SANDYIVY_PWMMAX 0x710
#define HASWELL_PWMMAX 0xad9
#define SKYLAKE_PWMMAX 0x56c

    External(RMCF.BKLT, IntObj)
    External(RMCF.LMAX, IntObj)

    External(_SB.PCI0.IGPU, DeviceObj)
    Scope(_SB.PCI0.IGPU)
    {
        // need the device-id from PCI_config to inject correct properties
        OperationRegion(IGD5, PCI_Config, 0, 0x14)
    }
    Device (_SB.PCI0.IGPU.PNLF)
    {
        Name(_ADR, Zero)
        Name(_HID, EisaId ("APP0002"))
        Name(_CID, "backlight")
        Name(_UID, 15)
        Name(_STA, 0x0B)
        Name(RMCF, Package()
        {
            "PWMMax", Zero
        })

        Field(^IGD5, AnyAcc, NoLock, Preserve)
        {
            Offset(0x02), GDID,16,
            Offset(0x10), BAR1,32,
        }

        OperationRegion(RMB1, SystemMemory, BAR1 & ~0xF, 0xe1184)
        Field(RMB1, AnyAcc, Lock, Preserve)
        {
            Offset(0x48250),
            LEV2, 32,
            LEVL, 32,
            Offset(0x70040),
            P0BL, 32,
            Offset(0xc8250),
            LEVW, 32,
            LEVX, 32,
            Offset(0xe1180),
            PCHL, 32,
        }
   
	Method(_INI)
        {
            // IntelBacklight.kext takes care of this at load time...
            // If RMCF.BKLT does not exist, it is assumed you want to use AppleBacklight.kext...
            If (CondRefOf(\RMCF.BKLT)) { If (1 != \RMCF.BKLT) { Return } }

            // Adjustment required when using AppleBacklight.kext
            Local0 = GDID
            Local2 = Ones
            if (CondRefOf(\RMCF.LMAX)) { Local2 = \RMCF.LMAX }

            If (Ones != Match(Package()
            {
                // Sandy
                0x0116, 0x0126, 0x0112, 0x0122,
                // Ivy
                0x0166, 0x016a,
                // Arrandale
                0x42, 0x46
            }, MEQ, Local0, MTR, 0, 0))
            {
                // Sandy/Ivy
                if (Ones == Local2) { Local2 = SANDYIVY_PWMMAX }

                // change/scale only if different than current...
                Local1 = LEVX >> 16
                If (!Local1) { Local1 = Local2 }
                If (Local2 != Local1)
                {
                    // set new backlight PWMMax but retain current backlight level by scaling
                    Local0 = (LEVL * Local2) / Local1
                    //REVIEW: wait for vblank before setting new PWM config
                    //For (Local7 = P0BL, P0BL == Local7, ) { }
                    Local3 = Local2 << 16
                    If (Local2 > Local1)
                    {
                        // PWMMax is getting larger... store new PWMMax first
                        LEVX = Local3
                        LEVL = Local0
                    }
                    Else
                    {
                        // otherwise, store new brightness level, followed by new PWMMax
                        LEVL = Local0
                        LEVX = Local3
                    }
                }
            }
            Else
            {
                // otherwise... Assume Haswell/Broadwell/Skylake
                if (Ones == Local2)
                {
                    // check Haswell and Broadwell, as they are both 0xad9 (for most common ig-platform-id values)
                    If (Ones != Match(Package()
                    {
                        // Haswell
                        0x0d26, 0x0a26, 0x0d22, 0x0412, 0x0416, 0x0a16, 0x0a1e, 0x0a1e, 0x0a2e, 0x041e, 0x041a,
                        // Broadwell
                        0x0BD1, 0x0BD2, 0x0BD3, 0x1606, 0x160e, 0x1616, 0x161e, 0x1626, 0x1622, 0x1612, 0x162b,
                    }, MEQ, Local0, MTR, 0, 0))
                    {
                        Local2 = HASWELL_PWMMAX
                    }
                    Else
                    {
                        // assume Skylake/KabyLake, both 0x56c
                        // 0x1916, 0x191E, 0x1926, 0x1927, 0x1912, 0x1932, 0x1902, 0x1917, 0x191b,
                        // 0x5916, 0x5912, 0x591b, others...
                        Local2 = SKYLAKE_PWMMAX
                    }
                }

                // This 0xC value comes from looking what OS X initializes this\n
                // register to after display sleep (using ACPIDebug/ACPIPoller)\n
                LEVW = 0xC0000000

                // change/scale only if different than current...
                Local1 = LEVX >> 16
                If (!Local1) { Local1 = Local2 }
                If (Local2 != Local1)
                {
                    // set new backlight PWMAX but retain current backlight level by scaling
                    Local0 = (((LEVX & 0xFFFF) * Local2) / Local1) | (Local2 << 16)
                    //REVIEW: wait for vblank before setting new PWM config
                    //For (Local7 = P0BL, P0BL == Local7, ) { }
                    LEVX = Local0
                }
            }

            // Now Local2 is the new PWMMax, set _UID accordingly
            // The _UID selects the correct entry in AppleBacklightInjector.kext
            If (Local2 == SANDYIVY_PWMMAX) { _UID = 14 }
            ElseIf (Local2 == HASWELL_PWMMAX) { _UID = 15 }
            ElseIf (Local2 == SKYLAKE_PWMMAX) { _UID = 16 }
            Else { _UID = 99 }
            
	// Disable discrete graphics (Nvidia) if it is present
            External(\_SB.PCI0.PEG0.PEGP._OFF, MethodObj)
            If (CondRefOf(\_SB.PCI0.PEG0.PEGP._OFF))
            {
                \_SB.PCI0.PEG0.PEGP._OFF()
            }
        }
    }
    
    // Brightness Keys Fix
    
    Device (PS2K)
    {
        Name (_HID, "RMKB0000")
    }
    
    External(_SB.PCI0.LPCB.EC0, DeviceObj)

    Scope (_SB.PCI0.LPCB.EC0)
    {
        Method (_Q11, 0, NotSerialized)
        {
            Notify (PS2K, 0x0205)
            Notify (PS2K, 0x0285)
        }

        Method (_Q12, 0, NotSerialized)
        {
            Notify (PS2K, 0x0206)
            Notify (PS2K, 0x0286)
        }
    }

//
// Standard Additions/Injections/Fixes
//

    Scope(_SB.PCI0)
    {
        // Add the missing IMEI device
        
        Device(IMEI)
        {
            Name (_ADR, 0x00160000)
        }
        
        // Add the missing MCHC device
        
        Device (MCHC)
        {
            Name (_ADR, Zero)
        }
        
        // Add SMBBUS Device

        Device(SBUS.BUS0)
        {
            Name(_CID, "smbus")
            Name(_ADR, Zero)
            Device(DVL0)
            {
                Name(_ADR, 0x57)
                Name(_CID, "diagsvault")
                Method(_DSM, 4)
                {
                    If (!Arg2) { Return (Buffer() { 0x03 } ) }
                    Return (Package() { "address", 0x57 })
                }
            }
        }
    }
    
    // Automatic injection of IGPU properties

    External(_SB.PCI0.IGPU, DeviceObj)

    Scope(_SB.PCI0.IGPU)
    {
        Method (_DSM, 4)
        {
            If (!Arg2) { Return (Buffer() { 0x03 } ) }
            Return (Package ()
            {
                "device-id", Buffer () { 0x12, 0x04, 0x00, 0x00 }, 
                "AAPL,ig-platform-id", Buffer () { 0x06, 0x00, 0x26, 0x0A }, 
                "hda-gfx", Buffer () { "onboard-1" }, 
                "AAPL00,DualLink", Buffer () { 0x01, 0x00, 0x00, 0x00 }, 
                "model", Buffer () { "Intel HD 4600" },
            })
        }
    }

    // Automatic injection of HDAU properties
    
    External(_SB.PCI0.HDAU, DeviceObj)
    
    Method(_SB.PCI0.HDAU._DSM, 4)
    {
        If (!Arg2) { Return (Buffer() { 0x03 } ) }
        Return (Package ()
        {
            "layout-id", Buffer() { 3, 0, 0, 0 },
            "hda-gfx", Buffer() { "onboard-1" },
        })
    }
    
    // Automatic injection of HDEF properties

    External(_SB.PCI0.HDEF, DeviceObj)
    
    Method(_SB.PCI0.HDEF._DSM, 4)
    {
        If (!Arg2) { Return (Buffer() { 0x03 } ) }
        Return(Package()
        {
            "layout-id", Buffer(4) { 3, 0, 0, 0 },
            "hda-gfx", Buffer() { "onboard-1" },
            "PinConfigurations", Buffer() { },
        })
    }

    // Fix _WAK
    
    External (ZWAK, MethodObj)
    
    Method (_WAK, 1, NotSerialized)
    {
        If (LOr (LLess (Arg0, One), LGreater (Arg0, 0x05)))
        {
            Store (0x03, Arg0)
        }

        Store (ZWAK (Arg0), Local0)
        Return (Local0)
    }
    
    // Fix unsupported 8-series LPC devices
    
    External(_SB.PCI0.LPCB, DeviceObj)

    Scope(_SB.PCI0.LPCB)
    {
        Method (_DSM, 4, NotSerialized)
        {
            If (!Arg2) { Return (Buffer() { 0x03 } ) }
            Return (Package () { "compatible", "pci8086,9c43" })
        }
    }

//
// Battery Status
//

    // Override for ACPIBatteryManager.kext
    
    External(_SB.BAT1, DeviceObj)
    Name(_SB.BAT1.RMCF, Package()
    {
        "StartupDelay", 10,
    })

    External (_SB.PCI0.LPCB.ECOK, MethodObj)
    External (_SB.PCI0.LPCB.EC0.ENDD, FieldUnitObj)
    External (_TZ.THLD, UnknownObj)
    External (_TZ.TZ00.PTMP, UnknownObj)
    
    Scope (_TZ)
    {
        Method (_TMP, 0, Serialized)
        {
            If (\_SB.PCI0.LPCB.ECOK ())
            {
                Store (Zero, \_SB.PCI0.LPCB.EC0.ENI0)
                Store (0x84, \_SB.PCI0.LPCB.EC0.ENI1)
                Store (\_SB.PCI0.LPCB.EC0.ENDD, Local0)
            }
            Else
            {
                Store (\_TZ.TZ00.PTMP, Local0)
            }

            If (LGreaterEqual (Local0, THLD))
            {
                Return (\_TZ.TZ00.PTMP)
            }
            Else
            {
                Add (0x0AAC, Multiply (Local0, 0x0A), Local0)
                Store (Local0, \_TZ.TZ00.PTMP)
                Return (Local0)
            }
        }
    }
    
    External(_SB.PCI0.LPCB.EC0, DeviceObj)
    External (FAMX, MutexObj)
    External (ERBD, FieldUnitObj)
    
    Scope (_SB.PCI0.LPCB.EC0)
    {
        OperationRegion (AMER, EmbeddedControl, Zero, 0xFF)
        Field (AMER, ByteAcc, Lock, Preserve)
        {
            Offset (0x5A), 
            Offset (0x5B), 
            Offset (0x5C), 
            Offset (0x5D), 
            ENI0,   8, 
            ENI1,   8
        }
        
        OperationRegion (RMEC, EmbeddedControl, Zero, 0xFF)
        Field (RMEC, ByteAcc, Lock, Preserve)
        {
            Offset (0x5D), 
            ERI0,   8, 
            ERI1,   8
        }

        Method (FANG, 1, NotSerialized)
        {
            Acquire (FAMX, 0xFFFF)
            Store (Arg0, ERI0)
            Store (ShiftRight (Arg0, 0x08), ERI1)
            Store (ERBD, Local0)
            Release (FAMX)
            Return (Local0)
        }

        Method (FANW, 2, NotSerialized)
        {
            Acquire (FAMX, 0xFFFF)
            Store (Arg0, ERI0)
            Store (ShiftRight (Arg0, 0x08), ERI1)
            Store (Arg1, ERBD)
            Release (FAMX)
            Return (Arg1)
        }
    }
}
//EOF
