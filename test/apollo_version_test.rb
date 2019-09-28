require 'minitest/autorun'
require 'apollo_version'

Minitest.autorun

class TestApolloVersion < Minitest::Test
  def test_find_in_frameworks_without_path
    assert_raises(ApolloVersion::NotFoundError) do
      ApolloVersion.find_in_frameworks!([])
    end
  end

  def test_find_in_frameworks_with_path
    Dir.mktmpdir do |dir|
      apollo_framework_path = File.expand_path('Apollo.framework', dir)
      Dir.mkdir(apollo_framework_path)
      info_plist_path = File.expand_path('Info.plist', apollo_framework_path)
      File.write(info_plist_path, 'CFBundleVersion = "0.13.0";')
      assert_equal ApolloVersion.new('0.13.0'), ApolloVersion.find_in_frameworks!([dir])
    end
  end

  def test_find_in_podfile_lock_without_path
    assert_raises(TypeError) do
      ApolloVersion.find_in_podfile_lock!(nil)
    end
  end

  def test_find_in_podfile_lock_with_path_of_valid_podfile_lock
    podfile_lock = <<-EOS
PODS:
  - Apollo (0.9.5):
    - Apollo/Core (= 0.9.5)
  - Apollo/Core (0.9.5)
  - ApolloDeveloperKit (0.3.3):
    - Apollo (< 0.13.0, >= 0.9.0)
    EOS
    Tempfile.create do |file|
      file.write(podfile_lock)
      file.rewind
      assert_equal ApolloVersion.new('0.9.5'), ApolloVersion.find_in_podfile_lock!(file.path)
    end
  end

  def test_find_in_podfile_lock_with_path_of_invalid_podfile_lock
    podfile_lock = <<-EOS
PODS:
  - Apollo/Core (0.9.5)
  - ApolloDeveloperKit (0.3.3):
    - Apollo (< 0.13.0, >= 0.9.0)
    EOS
    Tempfile.create do |file|
      file.write(podfile_lock)
      file.rewind
      assert_raises(ApolloVersion::NotFoundError) do
        ApolloVersion.find_in_podfile_lock!(file.path)
      end
    end
  end

  def test_greater_than
    assert_operator ApolloVersion.new('1.0.0'), :<, ApolloVersion.new('1.1.0')
  end

  def test_less_than
    assert_operator ApolloVersion.new('1.0.0'), :>, ApolloVersion.new('0.9.9')
  end
end
