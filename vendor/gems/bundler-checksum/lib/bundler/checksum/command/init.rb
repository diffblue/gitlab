# frozen_string_literal: true

module Bundler::Checksum::Command
  module Init
    extend self

    def execute
      # TODO Can we speed this up by using locally cached gem packages ?
      $stderr.puts "Initializing checksum file #{checksum_file}"

      checksums = []

      lockfile.specs.each do |spec|
        next unless spec.source.is_a?(Bundler::Source::Rubygems)

        remote_checksum = Helper.remote_checksums_for_gem(spec.name, spec.version)
        if remote_checksum.nil?
          raise "#{gem_name} #{gem_version} not found on rubygems !"
        end

        $stderr.puts "Adding #{spec.name}==#{spec.version}"
        checksums += remote_checksum
      end

      File.write(checksum_file, JSON.generate(checksums, array_nl: "\n") + "\n")
    end

    private

    def checksum_file
      ::Bundler::Checksum.checksum_file
    end

    def lockfile
      lockfile_path = Bundler.default_lockfile
      lockfile = Bundler::LockfileParser.new(Bundler.read_file(lockfile_path))
    end
  end
end
