class FooTest < MiniTest::Chef::TestCase
  def test_exist_file
    assert File.exist?('/tmp/temporal_file')
  end

  def test_succeed
    assert run_status.success?
  end
end
