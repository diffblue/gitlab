# frozen_string_literal: true

require 'json_schemer'

module RemoteDevelopment
  module Workspaces
    module Reconcile
      class ParamsParser
        include UpdateType

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

        def validate_params(params)
          schema = JSONSchemer.schema({
            "type" => "object",
            "required" => %w[update_type workspace_agent_infos],
            "properties" => {
              "update_type" => {
                "type" => "string",
                "enum" => [PARTIAL, FULL]
              },
              "workspace_agent_infos" => {
                "type" => "array"
              }
            }
          })

          errs = schema.validate(params)
          return if errs.none?

          errs.map { |err| JSONSchemer::Errors.pretty(err) }.join(". ")
        end
      end
    end
  end
end
