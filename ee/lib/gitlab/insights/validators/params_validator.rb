# frozen_string_literal: true

module Gitlab
  module Insights
    module Validators
      class ParamsValidator
        ParamsValidatorError = Class.new(StandardError)
        InvalidTypeError = Class.new(ParamsValidatorError)
        InvalidProjectsError = Class.new(ParamsValidatorError)
        InvalidQueryError = Class.new(ParamsValidatorError)

        SUPPORTER_TYPES = %w[bar line stacked-bar pie].freeze

        def initialize(params)
          @params = params
        end

        def validate!
          unless SUPPORTER_TYPES.include?(params[:type])
            raise InvalidTypeError, "Invalid `:type`: `#{params[:type]}`. Allowed values are #{SUPPORTER_TYPES}!"
          end

          if params[:projects]
            unless params[:projects].is_a?(Hash) || params[:projects].is_a?(ActionController::Parameters)
              raise InvalidProjectsError, "Invalid `:projects`: `#{params[:projects]}`. It should be a hash."
            end

            unless params.dig(:projects, :only).is_a?(Array)
              raise InvalidProjectsError, "Invalid `:projects`.`only`: `#{params.dig(:projects, :only)}`. It should be an array."
            end
          end
        end

        private

        attr_reader :params
      end
    end
  end
end
