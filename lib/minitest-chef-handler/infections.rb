require 'chef'

module MiniTest
  module Chef
    module Infections extend ::Chef::Mixin::ConvertToClassName

      def self.infect_resource(resource, meth, new_name)
        clazz = ::Chef::Resource.const_get(convert_to_class_name(resource.to_s))
        clazz.infect_an_assertion "assert_#{meth}".to_sym,
          "must_#{new_name}".to_sym, :only_one_argument
        clazz.infect_an_assertion "refute_#{meth}".to_sym,
          "wont_#{new_name}".to_sym, :only_one_argument
      end

      infect_resource :cron, :cron_exists, :exist
      infect_resource :directory, :modified_after, :be_modified_after
      infect_resource :directory, :path_exists, :exist
      infect_resource :file, :includes_content, :include
      infect_resource :file, :matches_content, :match
      infect_resource :file, :modified_after, :be_modified_after
      infect_resource :file, :path_exists, :exist
      infect_resource :group, :group_exists, :exist
      infect_resource :ifconfig, :ifconfig_exists, :exist
      infect_resource :link, :link_exists, :exist
      infect_resource :mount, :mounted, :be_mounted
      infect_resource :mount, :mount_enabled, :be_enabled
      infect_resource :service, :enabled, :be_enabled
      infect_resource :service, :running, :be_running
      infect_resource :package, :installed, :be_installed
      infect_resource :user, :user_exists, :exist

      ::Chef::Resource::Group.infect_an_assertion :assert_group_includes, :must_include
      ::Chef::Resource::Group.infect_an_assertion :refute_group_includes, :wont_include

    end
  end
end
