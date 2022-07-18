require 'json'
require 'net/http'

require 'bundler'
require 'bundler/checksum/lib'
require 'bundler/checksum/version'

module Bundler::Checksum::CLI
  extend self

  def run(args=ARGV)
    if args.empty?
      puts 'A command must be given [init,update,verify]'
    end

    if args.first == 'init'
      lockfile_path = Bundler.default_lockfile
      checksumfile_path = "#{File.dirname(lockfile_path)}/Gemfile.checksum"

      $stderr.puts "Initializing checksum file #{checksumfile_path}"

      lockfile = Bundler::LockfileParser.new(Bundler.read_file(lockfile_path))
      checksums = []

      lockfile.specs.each do |spec|
        next unless spec.source.is_a?(Bundler::Source::Rubygems)

        remote_checksum = remote_checksums_for_gem(spec.name, spec.version)
        next if remote_checksum.nil?

        checksum_row = {
          'name': spec.name,
          'version': spec.version.to_s,
          'checksum': remote_checksum
        }

        $stderr.puts "Adding #{spec.name}==#{spec.version}"
        checksums.append(checksum_row)
      end

      File.write(checksumfile_path, JSON.pretty_generate(checksums))

    elsif args.first == 'update'
      puts 'Updating checksum'
    elsif args.first == 'verify'
      $stderr.puts 'Verifying bundle'
      lockfile_path = Bundler.default_lockfile
      checksumfile_path = "#{File.dirname(lockfile_path)}/Gemfile.checksum"

      lockfile = Bundler::LockfileParser.new(Bundler.read_file(lockfile_path))
      checksums = []

      deps = ::Bundler::Definition
       .build(Bundler.default_gemfile, Bundler.default_lockfile, nil)
       .tap(&:validate_runtime!)

      deps.specs.each do |spec|
        next unless spec.source.is_a?(Bundler::Source::Rubygems)
        $stderr.puts "Verifying #{spec.name}==#{spec.version} #{spec.platform}"
        validate_gem_checksum(spec.name, spec.version, spec.platform, checksumfile_path)
      end
    end
  end
end
