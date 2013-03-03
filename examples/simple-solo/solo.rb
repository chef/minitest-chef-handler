require 'minitest-chef-handler'

path = File.expand_path('{test/test_*,spec/*_spec}.rb', File.dirname(__FILE__))
cache = File.expand_path('cache', File.dirname(__FILE__))

report_handlers << MiniTest::Chef::Handler.new(:path => path)
cookbook_path File.expand_path('cookbooks', File.dirname(__FILE__))
file_cache_path '/tmp/chef-solo-cache'
log_location 'chef.log'
cache_options({ :path => cache, :skip_expires => true })
file_cache_path cache
