require 'set'

module MiniTest
  module Chef
    module Assertions

      def self.resource_exists(name, options)
        options[:description] = name unless options[:description]
        define_method("assert_#{name}_exists") do |resource|
          refute resource.send(options[:field]).nil?,
            "Expected #{options[:description]} '#{resource.name}' to exist"
          resource
        end
        define_method("refute_#{name}_exists") do |resource|
          assert resource.send(options[:field]).nil?,
            "Expected #{options[:description]} '#{resource.name}' to not exist"
          resource
        end
      end

      resource_exists :cron,     :field => :command, :description => 'cron entry'
      resource_exists :group,    :field => :gid
      resource_exists :ifconfig, :field => :device, :description => 'network interface'
      resource_exists :link,     :field => :to
      resource_exists :user,     :field => :uid

      def assert_enabled(service)
        assert service.enabled, "Expected service '#{service.name}' to be enabled"
        service
      end

      def refute_enabled(service)
        refute service.enabled, "Expected service '#{service.name}' to not be enabled"
        service
      end

      def assert_group_includes(members, group)
        members = Set.new(Array(members))
        assert Set.new(group.members) & members == members,
          "Expected group '#{group.name}' to include members: #{members.to_a.join(', ')}"
        group
      end

      def refute_group_includes(members, group)
        members = Set.new(Array(members))
        refute Set.new(group.members) & members == members,
          "Expected group '#{group.name}' not to include members: #{members.to_a.join(', ')}"
        group
      end

      def assert_includes_content(file, content)
        assert File.read(file.path).include?(content), "Expected file '#{file.path}' to include the specified content"
        file
      end

      def refute_includes_content(file, content)
        refute File.read(file.path).include?(content), "Expected file '#{file.path}' not to include the specified content"
        file
      end

      def assert_installed(package)
        refute package.version.nil?, "Expected package '#{package.name}' to be installed"
        package
      end

      def refute_installed(package)
        assert package.version.nil?, "Expected package '#{package.name}' to not be installed"
        package
      end

      def assert_matches_content(file, regexp)
        assert File.read(file.path).match(regexp), "Expected the contents of file '#{file.path}' to match the regular expression '#{regexp}'"
        file
      end

      def refute_matches_content(file, regexp)
        refute File.read(file.path).match(regexp), "Expected the contents of file '#{file.path}' not to match the regular expression '#{regexp}'"
        file
      end

      def assert_modified_after(file_or_dir, time)
        assert File.mtime(file_or_dir.path).to_i >= time.to_i, "Expected the file '#{file_or_dir.path}' to have been modified after '#{time}'"
        file_or_dir
      end

      def refute_modified_after(file_or_dir, time)
        refute File.mtime(file_or_dir.path) >= time, "Expected the file '#{file_or_dir.path}' not to have been modified after '#{time}'"
        file_or_dir
      end

      def assert_mounted(mount)
        assert mount.mounted, "Expected mount point '#{mount.name}' to be mounted"
        mount
      end

      def refute_mounted(mount)
        refute mount.mounted, "Expected mount point '#{mount.name}' to not be mounted"
        mount
      end

      def assert_mount_enabled(mount)
        assert mount.enabled, "Expected mount point '#{mount.name}' to be enabled"
        mount
      end

      def refute_mount_enabled(mount)
        refute mount.enabled, "Expected mount point '#{mount.name}' to not be enabled"
        mount
      end

      def assert_path_exists(file_or_dir)
        assert File.exists?(file_or_dir.path), "Expected path '#{file_or_dir.path}' to exist"
        file_or_dir
      end

      def refute_path_exists(file_or_dir)
        refute File.exists?(file_or_dir.path), "Expected path '#{file_or_dir.path}' not to exist"
        file_or_dir
      end

      def assert_running(service)
        assert service.running, "Expected service '#{service.name}' to be running"
        service
      end

      def refute_running(service)
        refute service.running, "Expected service '#{service.name}' not to be running"
        service
      end

      def assert_directory(dir, *args)
        assert File.directory?(dir), "Expected #{dir} to be a directory"
        assert_acl(dir, *args)
      end

      def assert_file(file, *args)
        assert File.file?(file), "Expected #{file} to be a file"
        assert_acl(file, *args)
      end

      def assert_acl(file, owner, group, mode)
        unless File.directory?(file)
          file(file).
            must_have(:owner, owner).
            must_have(:group, group).
            must_have(:mode, mode)
        else
          directory(file).
            must_have(:owner, owner).
            must_have(:group, group).
            must_have(:mode, mode)
        end
      end

      def assert_symlinked_file(file, *args)
        assert File.symlink?(file), "Expected #{file} to be a symlink"
        assert File.read(file, 1), "Expected #{file} to be linked to an existing file"
        assert_acl file, *args
      end

      def assert_symlinked_directory(directory, *args)
        assert File.symlink?(directory), "Expected #{directory} to be a symlink"
        assert_sh "ls #{directory}/", "Expected #{directory} to link to an existing directory"
        assert_acl directory, *args
      end

      def assert_logrotate(file)
        assert_file file, "root", "root", 0644
        assert_sh "logrotate -d #{file}", "Expected #{file} to pass logrotate validation"
      end

      def assert_sh(command, text=nil)
        text ||= "Expected #{command} to succeed"
        out = `#{command.strip} 2>&1`
        assert $?.success?, "#{text}, but failed with: #{out}"
        out
      end

      def refute_sh(command, text=nil)
        text ||= "Expected #{command} not to succeed"
        out = `#{command.strip} 2>&1`
        assert !$?.success?, "#{text}, but succeeded with: #{out}"
        out
      end
    end
  end
end
