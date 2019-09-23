require 'find'
require 'shellwords'
require 'rubygems'

class ApolloVersion
  include Comparable

  attr_reader :version

  def initialize(framework_search_paths = nil)
    framework_search_paths ||= ENV['FRAMEWORK_SEARCH_PATHS'].shellsplit
    Find.find(*framework_search_paths) do |path|
      if path.end_with?('Apollo.framework/Info.plist')
        @version = `/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' #{path.shellescape}`.chomp
        return
      end
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
