# frozen_string_literal: true

require 'json'
require 'net/http'

module Bundler::Checksum::Command
  # TODO Move into organised classes
  module Helper
    extend self

    def remote_checksums_for_gem(gem_name, gem_version)
      response = Net::HTTP.get_response(URI(
        "https://rubygems.org/api/v1/versions/#{gem_name}.json"
      ))

      if response.code == '200'
        gem_candidates = JSON.parse(response.body, symbolize_names: true)
        gem_candidates.select! { |g| g[:number] == gem_version.to_s }

        gem_candidates.map {
          |g| {:name => gem_name, :version => gem_version, :platform => g[:platform], :checksum => g[:sha]}
        }
      end
    end

    def validate_gem_checksum(gem_name, gem_version, gem_platform, local_checksum)
      remote_checksums = remote_checksums_for_gem(gem_name, gem_version)
      if remote_checksums.nil? || remote_checksums.empty?
        $stderr.puts "#{gem_name} #{gem_version} not found on rubygems, skipping"
        return false
      end

      remote_platform_checksum = remote_checksums.find { |g| g[:name] == gem_name && g[:platform] == gem_platform.to_s }

      if local_checksum == remote_platform_checksum[:checksum]
        true
      else
        $stderr.puts "Gem #{gem_name} #{gem_version} #{gem_platform} failed checksum verification"
        $stderr.puts "LOCAL:  #{local_platform_checksum[:checksum]}"
        $stderr.puts "REMOTE: #{remote_platform_checksum[:checksum]}"
        return false
      end
    end
  end
end
