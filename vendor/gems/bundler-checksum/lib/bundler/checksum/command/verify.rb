# frozen_string_literal: true

module Bundler::Checksum::Command
  module Verify
    extend self

    def execute
      # TODO Is verify the same as running init again, and ensuring there's no diffs ?
      $stderr.puts 'Verifying bundle checksums'

      local_checksums = JSON.parse(File.open(checksum_file).read, symbolize_names: true)
      verified = true

      local_checksums.each do |gem|
        name = gem.fetch(:name)
        version = gem.fetch(:version)
        platform = gem.fetch(:platform)
        checksum = gem.fetch(:checksum)

        $stderr.puts "Verifying #{name}==#{version} #{platform}"
        unless Helper.validate_gem_checksum(name, version, platform, checksum)
          verified = false
        end
      end

      verified
    end

    private

    def checksum_file
      ::Bundler::Checksum.checksum_file
    end
  end
end
