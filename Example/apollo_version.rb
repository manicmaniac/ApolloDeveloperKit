require 'find'
require 'rubygems/version'
require 'shellwords'

class ApolloVersion
  include Comparable

  attr_reader :version

  alias_method :to_s, :version

  def initialize(version)
    raise "'#{version}' cannot be parsed as a version." unless Gem::Version.correct?(version)
    @version = version
  end

  def self.find_in_frameworks(framework_search_paths = nil)
    framework_search_paths ||= ENV['FRAMEWORK_SEARCH_PATHS'].shellsplit
    Find.find(*framework_search_paths) do |path|
      return new(parse_version_from_info_plist(path)) if path.end_with?('Apollo.framework/Info.plist')
    end
    raise 'Apollo.framework not found.'
  end

  def <=>(other)
    # Borrowing the logic to compare versions from `Gem::Version`.
    Gem::Version.new(@version) <=> Gem::Version.new(other.to_s)
  end

  private

  def self.parse_version_from_info_plist(path)
    `/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' #{path.shellescape}`.chomp
  end
end
