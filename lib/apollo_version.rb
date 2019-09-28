require 'find'
require 'rubygems/version'
require 'shellwords'
require 'yaml'

class ApolloVersion
  class NotFoundError < StandardError
    def initialize(msg = 'Apollo.framework not found.')
      super(msg)
    end
  end

  include Comparable

  attr_reader :version

  alias_method :to_s, :version

  def initialize(version)
    raise(TypeError, 'version cannot be nil.') if version.nil?
    raise(ArgumentError, "'#{version}' cannot be parsed as a version.") unless version.empty? || Gem::Version.correct?(version)
    @version = version
  end

  def self.find!
    begin
      find_in_podfile_lock!
    rescue
      find_in_frameworks!
    end
  end

  def self.find_in_frameworks!(framework_search_paths = default_framework_search_paths)
    Find.find(*framework_search_paths) do |path|
      next unless path.end_with?('Apollo.framework/Info.plist')
      return new(parse_version_from_info_plist(path))
    end
    raise(NotFoundError.new)
  end

  def self.find_in_podfile_lock!(podfile_lock_path = default_podfile_lock_path)
    new(parse_version_from_podfile_lock(podfile_lock_path))
  end

  def <=>(other)
    # Borrowing the logic to compare versions from `Gem::Version`.
    Gem::Version.new(@version) <=> Gem::Version.new(other.to_s)
  end

  private

  def self.default_framework_search_paths
    ENV.fetch('FRAMEWORK_SEARCH_PATHS', '').shellsplit
  end

  def self.default_podfile_lock_path
    pods_root = ENV['PODS_ROOT']
    File.expand_path('../Podfile.lock', pods_root) if pods_root
  end

  def self.parse_version_from_info_plist(path)
    output = `/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' #{path.shellescape}`.chomp
    output.empty? ? raise(NotFoundError.new) : output
  end

  def self.parse_version_from_podfile_lock(path)
    pods = YAML.load(File.read(path))['PODS']
    pods.each do |pod|
      pod = pod.keys.first if pod.is_a?(Hash)
      match_data = pod.match(/^Apollo \(([0-9.]+)\)$/)
      return match_data[1] if match_data
    end
    raise(NotFoundError.new)
  end
end
