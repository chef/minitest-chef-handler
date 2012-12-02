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

          # in Chef 10.14.0 an additional argument was added to Chef::Platform.provider_for_resource
          # so we check the version here and use it if it is available
          if Gem::Version.new(::Chef::VERSION) < Gem::Version.new("10.14.0")
            provider = ::Chef::Platform.provider_for_resource(res)
          else
            provider = ::Chef::Platform.provider_for_resource(res, :create)
          end

          provider.load_current_resource
          provider.current_resource
        end
      end

      [:cron, :directory, :file, :group,
       :link, :package, :service, :user].each{ |r| register_resource(r) }

      register_resource(:ifconfig, :device)
      register_resource(:mount, :device)

      ::Chef::Resource.class_eval do
        def with(attribute, values)
          mt = Object.extend(MiniTest::Assertions)
          actual_values = resource_value(attribute)
          mt.assert_equal values, actual_values,
            "The #{resource_name} does not have the expected #{attribute}"
          self
        end

        alias :and :with
        alias :must_have :with

        private

        def resource_value(attribute)
          case attribute
            when :mode
              return nil unless mode
              mode.kind_of?(Integer) ? mode.to_s(8) : mode.to_s
            when :owner || :user
              return nil unless owner
              owner.is_a?(Integer) ? Etc.getpwuid(owner).name : Etc.getpwnam(owner).name
            when :group
              return nil unless group
              group.is_a?(Integer) ? Etc.getgrgid(group).name : Etc.getgrnam(group).name
            else send(attribute)
          end
        end
      end
    end
  end
end
