
passed_arguments = ENV['PASSED_ARGS'] || " "    

Vagrant.configure("2") do |config|
    config.vm.define "vmdocker" do |vm|

        vm.vm.box = "ubuntu/jammy64" # refers to Ubuntu 22.04 LTS
        vm.vm.hostname = "vmdocker"
        vm.vm.synced_folder "./workdir", "/home/vagrant/app", owner: "vagrant", group: "vagrant"
        vm.vm.network "public_network", ip: "192.168.1.106", bridge: "Intel(R) Wi-Fi 6 AX201 160MHz"
        vm.vm.network "forwarded_port", guest: 80, host: 8080 # Forward port 80 on the guest to port 8080 on the localhost
        vm.vm.boot_timeout = 360

        config.vm.provider "virtualbox" do |vb|
            vb.memory = 1024
            vb.cpus = 1
        end
    
        services = ENV['SERVICES'] || 'none'
        services = services.split(",") 

        # Provision Docker Compose if requested
        if services.include?('docker-compose')
            vm.vm.provision(
                "shell", 
                path: "provision.sh", 
                args: "first_arg second_arg #{passed_arguments}"
            )
        end

    end

end
  