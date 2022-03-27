# Variables which can be affected via commandline or by manual changing of variable values
$debug = true
$MODSHOT_URL="https://github.com/Speak2Erase/OSFM-Core-Public"
$OSMOD_URL="https://github.com/Speak2Erase/OSFM-GitHub"

def dbg_puts(message) 
    if $debug == true
        puts "Debug: " + message
    end
end

puts "------------------------------------------------------------"
puts "Welcome to OneShot: Linux Build Script for dummies!"
puts "It's not ENTIRELY automatic, you will have to do some stuff manually"
puts "But this script will guide you through then needed"
puts "Good luck!"
puts "------------------------------------------------------------"

#sleep 2

# [ANCHOR] | Stage 1: Look for VirtualBox
vboxpath = ""

puts "Searching for Oracle VirtualBox Hypervisor in PATH..."
if ENV["PATH"].size == 0
    puts "PATH Environment Path is corrupt. Please, relaunch Windows Command Line."
    exit
end
patharray = ENV["PATH"].split(";")
for el in patharray do
    if el.include? "VirtualBox"
        puts "Searching for Oracle VirtualBox Hypervisor in PATH... \e[32mYes\e[0m [" + el +"]"
        vboxpath = el
        break
    end
end

if vboxpath == ""
    puts "Searching for Oracle VirtualBox Hypervisor in PATH... \e[31mNo\e[0m"
    puts "Searching for Oracle VirtualBox Hypervisor in it's default path..."

    if File.directory? "C:\\Program Files\\Oracle\\VirtualBox"
        puts "Searching for Oracle VirtualBox Hypervisor in it's default path... \e[32mYes\e[0m [C:\\Program Files\\Oracle\\VirtualBox]"
        vboxpath = "C:\\Program Files\\Oracle\\VirtualBox"
    else
        puts "Searching for Oracle VirtualBox Hypervisor in it's default path... \e[31mNo\e[0m"
        puts "Oracle VirtualBox Hypervisor not found. Can you specify it's path? [if not, press enter]"
        vboxpath = gets.chomp

        if vboxpath == ""
            puts "Oracle VirtualBox Hypervisor is not present in system. Please, install it from this link or Oracle's Website: https://download.virtualbox.org/virtualbox/6.1.32/VirtualBox-6.1.32-149290-Win.exe"
            exit
        else
            if File.directory? vboxpath
                puts "Oracle VirtualBox Hypervisor detected. [" + vboxpath +"]"
            else 
                puts "Oracle VirtualBox Hypervisor is not present in system. Please, install it from this link or Oracle's Website: https://download.virtualbox.org/virtualbox/6.1.32/VirtualBox-6.1.32-149290-Win.exe"
                exit
            end
        end
    end
end

vboxmanage = "\"#{vboxpath}\\VBoxManage.exe\""
vmname = "\"OneShot Mod Virtual Machine\""
vmname_without_qm = "OneShot Mod Virtual Machine"

# [ANCHOR] | Stage 2: Download Ubuntu ISO.
iso_name = "ubuntu-21.10-desktop-amd64.iso"
iso_url = "https://releases.ubuntu.com/21.10/ubuntu-21.10-desktop-amd64.iso"
if !File.exists? iso_name
    puts "To download Canonical Ubuntu 20.10 ISO you will need 3 gigabytes on harddrive. Continue? [Default: yes]"
    confirm_prompt = gets.chomp
    if confirm_prompt == "yes" || confirm_prompt == "y" || confirm_prompt == ""
        system("wget #{iso_url}")
    end
end

# [ANCHOR] | Stage 3: Create VM
if !File.directory? "#{Dir.pwd}\\#{vmname_without_qm}"
    puts "Creating Virtual Machine"
    create_cmnd =  "#{vboxmanage} createvm --name #{vmname} --ostype \"Debian_64\" --register --basefolder \"#{Dir.pwd}\""
    dbg_puts "Executing #{create_cmnd}"
    system(create_cmnd)

    puts "Setting RAM and configuring network"
    apic_cmnd = "#{vboxmanage} modifyvm #{vmname} --ioapic on"
    dbg_puts "Executing: #{apic_cmnd}"
    system(apic_cmnd)

    ram_cmnd = "#{vboxmanage} modifyvm #{vmname} --memory 2048 --vram 128"
    dbg_puts "Executing: #{ram_cmnd}"
    system(ram_cmnd)

    net_cmnd = "#{vboxmanage} modifyvm #{vmname} --nic1 nat"
    dbg_puts "Executing: #{net_cmnd}"
    system(net_cmnd)
    puts "Done. Creating hard drive..."
    sata_cmnd = "#{vboxmanage} storagectl #{vmname} --name \"Main SATA Controller\" --add sata --controller IntelAhci"
    dbg_puts "Executing: #{sata_cmnd}"
    system(sata_cmnd)

    hdd_cmnd = "#{vboxmanage} createhd --filename \"#{Dir.pwd}/#{vmname_without_qm}/OneShot.vdi\" --size 70000 --format VDI"
    dbg_puts "Executing: #{hdd_cmnd}"
    system(hdd_cmnd)

    attach_cmnd = "#{vboxmanage} storageattach #{vmname} --storagectl \"Main SATA Controller\" --port 0 --device 0 --type hdd --medium \"#{Dir.pwd}/#{vmname_without_qm}/OneShot.vdi\""
    dbg_puts "Executing: #{attach_cmnd}"
    system(attach_cmnd)

    puts "Done. Installing Ubuntu on VM..."
    ide_cmnd = "#{vboxmanage} storagectl #{vmname} --name \"IDE Controller\" --add ide --controller PIIX4"
    dbg_puts "Executing: #{ide_cmnd}"
    system(ide_cmnd)

    isoattach_cmnd = "#{vboxmanage} storageattach #{vmname} --storagectl \"IDE Controller\" --port 0 --device 0 --type dvddrive --medium \"#{Dir.pwd}\\#{iso_name}\""
    dbg_puts "Executing: #{isoattach_cmnd}"
    system(isoattach_cmnd)

    gaattach_cmnd = "#{vboxmanage} storageattach #{vmname} --storagectl \"IDE Controller\" --port 1 --device 0 --type=dvddrive --medium \"#{vboxpath}\\VBoxGuestAdditions.iso\""
    dbg_puts "Executing: #{gaattach_cmnd}"
    system(gaattach_cmnd)

    if !File.directory? "shared"
        Dir.mkdir "shared"
    end
    sf_cmnd = "#{vboxmanage} sharedfolder add #{vmname} --name \"ossharedfolder\" --hostpath=\"#{Dir.pwd}\\shared\""
    dbg_puts "Executing: #{sf_cmnd}"
    system(sf_cmnd)
else puts "Virtual Machine already exists."
end

puts "Parsing oneshot_linux.sh.in..."
if !File.exists? "oneshot_linux.sh.in"
    puts "Parsing oneshot_linux.sh.in... \e[31mNo\e[0m"
    puts "oneshot_linux.sh.in doesn't exist. Exiting."
    exit
end

infile = File.open("oneshot_linux.sh.in", "r")
infile_contents = infile.read
infile.close
infile_contents = infile_contents.sub("{MODSHOT_URL}", $MODSHOT_URL)
infile_contents = infile_contents.sub("{OSMOD_URL}", $OSMOD_URL)

outfile = File.open("oneshot_linux.sh", "w+")
outfile.write infile_contents
outfile.close

puts "Parsing oneshot_linux.sh.in... \e[32mYes\e[0m"

puts "Done!"
puts "This script has created a Ubuntu 20.10 VM with Shared Folder."
puts " Shared Folder Path: #{Dir.pwd}\\shared"
puts " Ubuntu Username: twm"
puts " Ubuntu Password: ilikepancakes"
puts "To continue follow these steps: (these are post-install steps, you have to install Ubuntu first)"
puts "1. Open \"Files\" application (third icon in left menu) in Virtual Machine"
puts "2. Click on item with Disk icon on it - This will mount ISO to system"
puts "3. Right-click in File Explorer's File List area > Open in Terminal"
puts "4. Run \"sudo apt install gcc make perl; sudo sh autorun\" and follow instructions on screen."
puts "5. Reboot virtual machine."
puts "6. Open terminal (8-th icon) and run these commands:"
puts "      mkdir ~/host; sudo mount -t vboxsf ossharedfolder ~/host"
puts "      cd ~/host; sudo sh oneshot_linux.sh"
puts "Open Oracle VirtualBox Window? [Default: yes]"
vboxinput = gets.chomp
if vboxinput == "y" || vboxinput == "yes" || vboxinput == ""
    system("\"#{vboxpath}\\VirtualBox.exe\"")
end