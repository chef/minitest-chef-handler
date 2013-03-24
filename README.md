# Minitest Chef Handler

Run minitest suites after your Chef recipes to check the status of your system.

# Installation

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

Inside your tests cases, you still have access to Chef's `run_status`, `node` and `run_context`:

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

Inside your specs, you still have access to Chef's `run_status`, `node` and `run_context`:

```ruby
describe_recipe 'nginx:configuration' do
  it 'installs version 1.0.15' do
    node[:nginx][:version].should == '1.0.15'
  end
end
```

### Custom assertions

By including `MiniTest::Chef::Resources` and `MiniTest::Chef::Assertions` you
can also make assertions like these:

```ruby
file("/etc/fstab").must_have(:mode, "644")
package("less").must_be_installed
service("chef-client").must_be_running
assert_directory "/etc", "root", "root", "755"
assert_file "/etc/fstab", "root", "root", "644"
assert_sh "ls /etc"
assert_logrotate "/etc/logrotate.d/mysql"
```
and [many more](lib/minitest-chef-handler/assertions.rb)

The resources supported are: `cron`, `directory`, `file`, `group`, `ifconfig`,
`link`, `mount`, `package`, `service` and `user`.

For example usage see the tests under the `examples/spec_examples` directory.

## Further configuration

These are the options the handler accepts:

* :path => where your test files are, './test/test_*.rb' by default
* :filter => filter test names on pattern
* :seed => set random seed
* :verbose => show progress processing files.
* :ci_reports => path to write out the result of each test in a JUnit-compatible XML file, parseable by many CI platforms.

Example:

```ruby
handler = MiniTest::Chef::Handler.new({
  :path    => './cookbooks/test/*_test.rb',
  :filter  => 'foo',
  :seed    => srand,
  :verbose => true})

report_handlers << handler
```

## Automatic tests detection

MiniTest-chef-hander collects test paths based in the recipes ran.
It loads the tests based in the name of the cookbook and the name of the recipe.
The tests must be under the cookbooks directory.

Examples:

If the seen recipes includes the recipe "foo" we try to load tests from:

```
cookbooks/foo/tests/default_test.rb
cookbooks/foo/tests/default/*_test.rb

cookbooks/foo/specs/default_spec.rb
cookbooks/foo/specs/default/*_spec.rb
```

If the seen recipes includes the recipe "foo::install" we try to load tests from:

```
cookbooks/foo/tests/install_test.rb
cookbooks/foo/tests/install/*_test.rb

cookbooks/foo/specs/install_spec.rb
cookbooks/foo/specs/install/*_spec.rb
```

## Automatic chef failure

If the tests detect any failure, the handler raises an error to abort the
Chef execution. This error can be captured by any other exception handler
and be treated like any other error in the Chef execution.

## Chef server distribution

The instructions above have described how to use it in a Chef solo installation. If you want to distribute the handler to your Chef server check either the chef_handler cookbooks in the examples or [minitest-handler-cookbook](https://github.com/btm/minitest-handler-cookbook).

## Development

Minitest-chef-handler should work with versions 10.x and versions 11.x of Chef.

There are just two commands that you need to know to hack on this library.

1. Load both versions of Chef dependencies:

```
$ script/bootstrap
```

2. Run unit and integration tests agains both versions of Chef:

```
$ script/test
```

## Copyright

Copyright (c) 2012 David Calavera. See LICENSE for details.
