require 'find'
require 'shellwords'
require 'rubygems'

class ApolloVersion
  include Comparable

  attr_reader :version

  def initialize(version)
    @version = version
  end

  def self.guess
    ENV.has_key?('PODS_ROOT') ?  from_cocoapods : from_built_framework
  end

  def self.from_cocoapods(podfile_lock_path = nil)
    podfile_lock_path ||= File.expand_path('../Podfile.lock', ENV['PODS_ROOT'])
    new(`sed -ne 's/^ *- Apollo (\([0-9.]*\)):$/\\1/p' #{podfile_lock_path.shellescape}`.chomp)
  end

  def self.from_built_framework(framework_search_paths = nil)
    framework_search_paths ||= ENV['FRAMEWORK_SEARCH_PATHS'].shellsplit
    Find.find(*framework_search_paths) do |path|
      return new(`/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' #{path.shellescape}`.chomp) if path.end_with?('Apollo.framework/Info.plist')
    end
    raise 'Apollo.framework not found.'
  end

  def <=>(other)
    other_version = other.is_a?(self.class) ? other.version : other.to_s
    # Borrowing a logic to compare versions from `Gem::Version`.
    Gem::Version.new(@version) <=> Gem::Version.new(other_version)
  end

  def inspect
    @version
  end
end
