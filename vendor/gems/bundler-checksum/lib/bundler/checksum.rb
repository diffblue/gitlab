require 'bundler'
require 'bundler/checksum/lib'
require 'bundler/checksum/version'

module Bundler
  module Checksum
    class << self
      def register
        return if defined?(@registered) && @registered
        @registered = true

        @checksum_file = "#{File.join(File.dirname(Bundler.default_gemfile), 'Gemfile.checksum')}"

        Bundler::Plugin.add_hook('before-install-all') do |dependencies|
          # puts 'before-install-all hook!'
          unless File.exist?(@checksum_file)
            File.write(@checksum_file, "[]")
          end
        end

        Bundler::Plugin.add_hook('before-install') do |dependency|
          # puts 'before-install hook!'
          name = dependency.name
          version = dependency.spec.version.to_s
          platform = dependency.spec.platform.to_s

          validate_gem_checksum(name, version, platform, @checksum_file)
        end
      end
    end
  end
end
