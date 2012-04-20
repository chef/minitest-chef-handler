# Minitest Chef Handler

Run minitest suites after your Chef recipes to check the status of your system.

## Motivation

Working at Engine Yard I have to maintain a quite complicated set of Chef recipes that we use to set up our customers' instances. I need to be sure that everytime someone modifies those recipes, mostly myself, the provisioned services continue working as expected.

There are other solutions that evaluate the configured node after the recipes
are loaded without arriving to the converge phase, like [ChefSpec](https://github.com/acrmp/chefspec) or [rspec-chef](https://github.com/calavera/rspec-chef), but I needed something to write integration tests easily. I checked [chef-minitest](https://github.com/fujin/chef-minitest) but I'm still amazed by the ugly code that I have to write into the recipes to make it work.

## Installation

```
$ gem install minitest-chef-handler
```

## Usage

Add the report handler to your client.rb or solo.rb file:

```ruby
require 'minitest-chef-handler'

report_handlers << MiniTest::Chef::Handler.new
```

### Test cases

Write your tests as normal MiniTest cases extending from MiniTest::Chef::TestCase:

```ruby
class TestNginx < MiniTest::Chef::TestCase
  def test_config_file_exist
    assert File.exist?('/etc/nginx.conf')
  end
end
```

You still have access to Chef's `run_status`, `node` and `run_context` from your tests:

```ruby
class TestNginx < MiniTest::Chef::TestCase
  def test_succeed
    assert run_status.success?
  end
end
```

### Spec cases

Wrap your descriptions with a class extending from MiniTest::Chef::Spec:

```ruby
class NginxSpec < MiniTest::Chef::Spec
  describe 'configuration' do
    it 'creates nginx.conf'
  end
end
```

Use the prefix `recipe::` in your descriptions:

```ruby
describe "recipe::nginx::configuration" do
  it 'creates nginx.conf'
end
```

Or use `describe_recipe` to define your specs:

```ruby
describe_recipe "nginx::configuration" do
  it 'creates nginx.conf'
end
```

You still have access to Chef's `run_status`, `node` and `run_context` from your specs:

```ruby
describe_recipe 'nginx:configuration' do
  it 'installs version 1.0.15' do
    node[:nginx][:version].should == '1.0.15'
  end
end
```

By including `MiniTest::Chef::Resources` and `MiniTest::Chef::Assertions` you
can also make assertions like these:

```ruby
file("/etc/fstab").must_have(:mode, "644")
package("less").must_be_installed
service("chef-client").must_be_running
```

The resources supported are: `cron`, `directory`, `file`, `group`, `ifconfig`,
`link`, `mount`, `package`, `service` and `user`.

For example usage see the tests under the `examples/spec_examples` directory.

## Further configuration

These are the options the handler accepts:

* :path => where your test files are, './test/test_*.rb' by default
* :filter => filter test names on pattern
* :seed => set random seed
* :verbose => show progress processing files.

Example:

```ruby
handler = MiniTest::Chef::Handler.new({
  :path    => './cookbooks/test/*_test.rb',
  :filter  => 'foo',
  :seed    => srand,
  :verbose => true})

report_handlers << handler
```

## Chef server distribution

The instructions abow have described how to use it in a Chef solo installation. If you want to distribute the handler to your Chef server check either the chef_handler cookbooks in the examples or [minitest-handler-cookbook](https://github.com/btm/minitest-handler-cookbook).

## Copyright

Copyright (c) 2012 David Calavera. See LICENSE for details.
