# frozen_string_literal: true

require 'json_schemer'

module RemoteDevelopment
  module Workspaces
    module Reconcile
      class ParamsParser
        include UpdateType

        # @param [Hash] params
        # @return [Array<(Hash | nil, RemoteDevelopment::Error | nil)>]
        def parse(params:)
          error_message = validate_params(params)

          if error_message
            error = Error.new(
              message: error_message,
              reason: :unprocessable_entity
            )
            return [nil, error]
          end

          parsed_params = {
            workspace_agent_infos: params.fetch('workspace_agent_infos'),
            update_type: params.fetch('update_type')
          }
          [
            parsed_params,
            nil
          ]
        end

        private

        # @param [Hash] params
        # @return [void, String]
        def validate_params(params)
          workspace_error_details_schema = {
            "required" => %w[error_type],
            "properties" => {
              "error_type" => {
                "type" => "string",
                "enum" => [ErrorType::APPLIER]
              },
              "error_message" => {
                "type" => "string"
              }
            }
          }
          workspace_agent_info_schema = {
            "properties" => {
              "termination_progress" => {
                "type" => "string",
                "enum" => [TerminationProgress::TERMINATING, TerminationProgress::TERMINATED]
              },
              "error_details" => workspace_error_details_schema
            }
          }

          schema = {
            "type" => "object",
            "required" => %w[update_type workspace_agent_infos],
            "properties" => {
              "update_type" => {
                "type" => "string",
                "enum" => [PARTIAL, FULL]
              },
              "workspace_agent_infos" => {
                "type" => "array",
                "items" => workspace_agent_info_schema
              }
            }
          }
          schemer = JSONSchemer.schema(schema)

          errs = schemer.validate(params)
          return if errs.none?

          errs.map { |err| JSONSchemer::Errors.pretty(err) }.join(". ")
        end
      end
    end
  end
end
