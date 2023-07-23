# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Create
      class DevfileFlattener
        include Messages

        # @param [Hash] value
        # @return [Result]
        def self.flatten(value)
          value => { devfile_yaml: String => devfile_yaml }

          begin
            flattened_devfile_yaml = Devfile::Parser.flatten(devfile_yaml)
          rescue Devfile::CliError => e
            return Result.err(WorkspaceCreateDevfileFlattenFailed.new(details: e.message))
          end

          # NOTE: We do not attempt to rescue any exceptions from YAML.safe_load here because we assume that the
          #       Devfile::Parser gem will not produce invalid YAML. We own the gem, and will fix and add any regression
          #       tests in the gem itself. No need to make this domain code more complex, more coupled, and less
          #       cohesive by unnecessarily adding defensive coding against other code we also own.
          processed_devfile = YAML.safe_load(flattened_devfile_yaml)

          processed_devfile['components'] ||= []

          Result.ok(value.merge(processed_devfile: processed_devfile))
        end
      end
    end
  end
end
