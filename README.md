------------------------------------------------------------------------
Emulator setup scripts
------------------------------------------------------------------------

These scripts were developed on Mac OS/Big Sur installed. And you should
use at your own risk. No warranty. Anything that breaks, you get to
mop up and keep all the pieces.

MANY OTHER COMBINATIONS WORK. THE PURPOSE OF THIS SCRIPT IS TO PROVIDE
KNOWN GOOD INSTALLATION AND BOOT PARAMETERS.

```
        NetBSD  OpenBSD FreeBSD DragonFly Solaris Debian Plan9 Minix
------------------------------------------------------------------------
amd64   qemu    qemu    qemu    qemu%     +++     qemu   qmu^^ qemu
i386    qemu    qemu    qemu              qemu
sparc64	qemu    qemu++  qemu**
sparc   qemu			          qemu^
macppc  qemu***
arm64   qemu* 
hppa	qemu	(qemu^^^)

pmax    gxemul
cats	gxemul+

vax	simh

*   see section 2
**  has trouble booting with graphics (we use -nographic by default)
*** Needs approach for booting normally after installation. NetBSD-current
    install disc not available, but Qemu can boot 9.99.80.
+   gxemul says it works for NetBSD 4.0.1. I can't get 5* onwards to
    extract base.tgz. Kernel panic
++  regular boot asks for the root device - just use wd0a
+++ Solaris 10 for i386. I cannot get the 11 installation iso to boot 
    on amd64, but the VM images may work.
^   Solaris 7, 8 & 9 sparc will work but you need to sort drive geometries
    See doc/Solaris-sparc-789.txt or use the ready 8G image in images/
^^  Others may work - I haven't tried
^^^ OpenBSD/hppa asks for boot device on normal boot and gets stuck
    on pf. Boot single user and disable it in /etc/rc.conf.local
%   Installer gets stuck on both 5.8.2 and 5.8.3. Needs work.
```

------------------------------------------------------------------------
1. Qemu
------------------------------------------------------------------------

```
use-qemu-vm.sh [-i] [-c] [-n] [-d] [-t TargetDir] [OS [arch [ver]]]
 -i run installer ISO (i.e. setup)
 -P port - setup port forwarding from port to 22 (then you can
 			ssh -p port localhost)
 -c use -display curses
 -n use -nographic (overrides -c)  
 -X zap the ISO and download it
 -F just fetch the ISO
 -d more output  
    use -t to specify an alternative target directory for files
    
  OS as above
 
   * Sets up or boots a Qemu VM with OS and arch
   * if you specify -i, you get the setup routine and the ISO will
     be downloaded if needed and where possible. The script will try
     to boot the ISO.
     if you specify -c, we'll try to use "-display curses"
   * if you set the QEMUTARGET variable, the VMs will be put there 
     instead of in $HOME/Qemu. -t overrides
   * if the file system image doesn't exist, the script will default
     to setup mode
   * The default is NetBSD/amd64
   * you need to install qemu and curl (needs ca-certificates on some
     host platforms such as NetBSD)
   * During the install it will make life easier if you setup the 
     machine for DHCP if possible
   * At the end of the install, exit to a shell and "shutdown -p now"
     if possible or "halt". If Qemu doesn't exit, you can CTRL-C it
     when the guest OS has ceased.
     
   * -c is useful for environments such as AWS or where there is no
     useful graphics library. -c seems to work better with i386 &
     amd64. -n is better for the other platforms.

   * For FreeBSD, if you don't want RELEASE (e.g. you want BETA2)
     use -R. e.g.
     sh use-qemu-vm.sh -i -R BETA2 FreeBSD amd64 13.0

   * The script deposits a script called boot.sh in the VM directory
   which contains the command last used to boot the VM. So if you 
   are happy with the last run, you can use this script going forward.
```

CTRL-C will kill an qemu if it is running in a graphics window.
CTRL-A x will exit a qemu running in nographic mode.

The following work with this script:
* NetBSD/amd64, i386, sparc, sparc64, macppc (all 9.1)
* OpenBSD/amd64, i386, sparc64 (all 6.8, 6.9-beta)
* FreeBSD/i386, amd64, sparc64 (all 12.2, 13.0-beta)
* Solaris 10/i386
* Debian/amd64 (latest)
* Plan 9/amd64 (latest)

Many other combinations work with Qemu but you might have to
experiment with options to get it to work. For example:
* NetBSD/i386 1.4.3 - see the doc directory
* Solaris/sparc 7, 8 & 9 - see the doc directory

Quirks:
-------
* Make sure you are running Qemu >=5.2 if you want to run Sparc/Sparc64. 
  I cannot get these to boot on 5.1.
* There appears to be a bug in either Qemu or MacOS. I've seen this in
  a self-built Qemu (both 4.2.1 and 5.2) and 5.2 from homebrew. The 
  guest OS gets short reads on FTP and is missing a byte. I've written
  this up on my blog page.
* For Solaris, you will need to get the ISO images for x86 from Oracle
* Solaris 8 is availabe from archive.org:
https://archive.org/download/solaris8_703sparc/Solaris%208%20Installation%20HW%207-03%20SPARC%20%28705-0540-10%29%28Sun%20Microsystems%2C%20Inc.%29%28July%202003%29.iso
* NetBSD/macppc is slightly more involved:
      When booting normally the first time after installation, I've setup the boot to fail to drop to the boot prompt. To boot type:

      ```netbsd.macppc -a```

      The -a will instruct netbsd to ask you for the root filesystem 
      - use wd0a. This will get you a working system, but it is the install
      kernel. One consequence is that DHCP will not work as BPF is not in the install kernel - you can setup a static IP. e.g. 10.0.2.100/255.255.255.0 gateway 10.0.2.2 and DNS 10.0.2.3.
      
      The run script needs the iso to be present on the filesystem for something valid for OpenFirmware to boot. Going forward you could either 
      
      * build a CD ROM with a kernel built to use the hard drive image as root
      * you could setup an HFS partition in the disc image.
      
      For convenience, here is an ISO image with generic kernels for 9.0 and 9.1 with wd0 hardwired. (You **can't boot** from this ISO at the moment.)
      
      https://cp1888.files.wordpress.com/2021/03/netbsd-boot-macppc-9.iso_.zip
      
      Download the ISO and use this the boot the VM without any Openboot hassle:
     
```
cd ...where.the.vm.is...
qemu-system-ppc -m 1G -nographic -cdrom NetBSD-Boot-macppc-9.iso -net user,ipv6=no -net nic -boot c -prom-env boot-device=cd:,\ofwboot.xcf -prom-env boot-file=netbsd9.wd0 netbsd-disk-macppc.img
```
      
      Replace netbsd9.wd0 with netbsd91.wd0 for a 9.1 kernel.

* FreeBSD/sparc64 - only boots -nographic so I've made this the default
* Plan9/amd64 - if you follow the suggested installation, everything
  works. On boot you need to confirm the root device and answer "glenda"
  to the second question. This ought to be smoother.


Does not work:
--------------

* OpenBSD/macppc - can get it to the bootloader but it panics.
  With pmu options I can get the system to go further but it panics when
  probing the usb bus.
* FreeBSD/powerppc - hangs/panics during probe of vgapci0
* Solaris 8/sparc 64 - doesn't boot - immediate panic
* Solaris 10/sparc64 - doesn't boot (I read somewhere that the processor
  emulated in the VM is not sufficient for Solaris 10. Older versions
  might work.)
* NetBSD/arc doesn't boot -  but apparently others have had success.
* I cannot get Solaris 11 to boot on Qemu without panicing. It cannot
see the discs. Ironically I cannot get it to boot on Oracle VirtualBox
either - same panicing problem.
* Solaris 8/sparc - having trouble with the disc images

See also: 

* https://chrispinnock.com/stuff/running-systems-in-qemu/

The sparc64 bit was based on work in this article:
* https://virtuallyfun.com/wordpress/2015/01/14/netbsd-6-1-5-sparc64-on-qemu/
* https://wiki.qemu.org/Documentation/Platforms/SPARC

Solaris 8 and earlier investigation:
http://tyom.blogspot.com/2009/12/solaris-under-qemu-how-to.html

This was helpful for NetBSD/MacPPC:
* https://wiki.qemu.org/Documentation/Platforms/PowerPC

Archive.org holds old Solaris DVDs:
*  https://archive.org/details/solaris8_703sparc

------------------------------------------------------------------------
2. Qemu for NetBSD/arm64
------------------------------------------------------------------------

* Use setup-arm64.sh to get the latest bits and pieces including 
working firmware and root filesystem. This will also resize the filesystem
to 10G
* Use run-arm64.sh to run it. Inside the script you can change the
graphics options easily if you prefer not to run headless

------------------------------------------------------------------------
3. Gxemul
------------------------------------------------------------------------

```
./use-gxemul-vm.sh [-i] [OS [arch]]
```

will setup a VM running on gxemul on the first run (or with -i)
and will run it if it is setup already.

Gxemul builds nicely from sources on Mac OS X. You will need X11 (e.g.
XQuartz).

The following work:
* NetBSD/pmax 
* NetBSD/cats 4.0.1 (!)

(I've not tried others at this point. Years ago this emulator supported
many NetBSD ports.)

The following don't work:
* NetBSD/cats 5* onwards - boots but panics during base.tgz extract

------------------------------------------------------------------------
4. Simh & NetBSD/vax
------------------------------------------------------------------------

```
./use-simh-vm.sh [-i]
```

* Will help setup a NetBSD/vax virtual machine with SIMH
* SIMH needs to be installed first
* The first time you will need to type boot dua1:     
  not dual - it's a 1.
* For normal operation, you will need to type boot dua0:

