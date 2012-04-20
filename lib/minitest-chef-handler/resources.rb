require 'chef'
require 'etc'
require 'minitest/unit'

module MiniTest
  module Chef
    module Resources
      include ::Chef::Mixin::ConvertToClassName

      def self.register_resource(resource, *required_args)
        define_method(resource) do |name, *options|
          clazz = ::Chef::Resource.const_get(convert_to_class_name(resource.to_s))
          res = clazz.new(name, run_context)
          required_args.each do |arg|
            res.send(arg, options.first[arg])
          end
          provider = ::Chef::Platform.provider_for_resource(res)
          provider.load_current_resource
          provider.current_resource
        end
      end

      [:cron, :directory, :file, :group,
       :link, :package, :service, :user].each{ |r| register_resource(r) }

      register_resource(:ifconfig, :device)
      register_resource(:mount, :device)

      ::Chef::Resource.class_eval do
        include MiniTest::Assertions
        def with(attribute, values)
          actual_values = resource_value(attribute, values)
          assert_equal values, actual_values,
            "The #{resource_name} does not have the expected #{attribute}"
          self
        end
        alias :and :with
        alias :must_have :with
        private

        def resource_value(attribute, values)
          case attribute
            when :mode then mode.kind_of?(Integer) ? mode.to_s(8) : mode.to_s
            when :owner || :user then Etc.getpwuid(owner).name
            when :group then Etc.getgrgid(group).name
            else send(attribute)
          end
        end

      end

    end
  end
end
