# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Create
      # noinspection RubyConstantNamingConvention - See https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/code-inspection/why-are-there-noinspection-comments/
      class PreFlattenDevfileValidator
        include Messages

        # We must ensure that devfiles are not created with a schema version different than the required version
        REQUIRED_DEVFILE_SCHEMA_VERSION = '2.2.0'

        # @param [Hash] value
        # @return [Result]
        def self.validate(value)
          Result.ok(value)
                .and_then(method(:validate_schema_version))
                .and_then(method(:validate_parent))
        end

        # @param [Hash] value
        # @return [Result]
        def self.validate_schema_version(value)
          value => { devfile: Hash => devfile }

          minimum_schema_version = Gem::Version.new(REQUIRED_DEVFILE_SCHEMA_VERSION)
          devfile_schema_version_string = devfile.fetch('schemaVersion')
          begin
            devfile_schema_version = Gem::Version.new(devfile_schema_version_string)
          rescue ArgumentError
            return err(
              format(_("Invalid 'schemaVersion' '%{schema_version}'"), schema_version: devfile_schema_version_string)
            )
          end

          unless devfile_schema_version == minimum_schema_version
            return err(
              format(
                _("'schemaVersion' '%{given_version}' is not supported, it must be '%{required_version}'"),
                given_version: devfile_schema_version_string,
                required_version: REQUIRED_DEVFILE_SCHEMA_VERSION
              )
            )
          end

          Result.ok(value)
        end

        # @param [Hash] value
        # @return [Result]
        def self.validate_parent(value)
          value => { devfile: Hash => devfile }

          return err(_("Inheriting from 'parent' is not yet supported")) if devfile['parent']

          Result.ok(value)
        end

        # @param [String] details
        # @return [Result]
        def self.err(details)
          Result.err(WorkspaceCreatePreFlattenDevfileValidationFailed.new({ details: details }))
        end
      end
    end
  end
end
