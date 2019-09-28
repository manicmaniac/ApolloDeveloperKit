require 'find'
require 'rubygems/version'
require 'shellwords'
require 'yaml'

class ApolloVersion
  include Comparable

  attr_reader :version

  alias_method :to_s, :version

  def initialize(version)
    raise "'#{version}' cannot be parsed as a version." unless Gem::Version.correct?(version)
    @version = version
  end

  def self.find!
    find_in_podfile_lock || find_in_frameworks || raise('Apollo.framework not found.')
  end

  def self.find_in_frameworks(framework_search_paths = nil)
    framework_search_paths ||= ENV['FRAMEWORK_SEARCH_PATHS'].shellsplit
    Find.find(*framework_search_paths) do |path|
      if path.end_with?('Apollo.framework/Info.plist')
        version = parse_version_from_info_plist(path)
        return new(version) if version
      end
    end
  end

  def self.find_in_podfile_lock(podfile_lock_path = nil)
    podfile_lock_path ||= File.expand_path('../Podfile.lock', ENV['PODS_ROOT'])
    version = parse_version_from_podfile_lock(podfile_lock_path)
    new(version) if version
  end

  def <=>(other)
    # Borrowing the logic to compare versions from `Gem::Version`.
    Gem::Version.new(@version) <=> Gem::Version.new(other.to_s)
  end

  private

  def self.parse_version_from_info_plist(path)
    `/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' #{path.shellescape}`.chomp
  end

  def self.parse_version_from_podfile_lock(path)
    yaml = YAML.load(File.read(path))
    yaml['PODS'].lazy
                .map { |entry| entry.is_a?(Hash) ? entry.keys.first : entry }
                .map { |pod| pod.match(/^Apollo \(([0-9.]+)\)$/) }
                .reject(&:nil?)
                .first[1]
  rescue
    nil
  end
end
