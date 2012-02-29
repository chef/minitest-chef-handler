Vagrant::Config.run do |config|
  config.vm.box = "natty64"
  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = "examples/cookbooks"
    chef.add_recipe "chef_handler::minitest"
    chef.add_recipe "foo"
  end
end
