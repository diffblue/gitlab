# frozen_string_literal: true

module Gitlab
  module Vulnerabilities
    module Cvss
      class ParameterSet
        def initialize(metrics)
          @parameters = metrics.map do |metric|
            Parameter.new(
              key: metric[:key],
              valid_values: metric[:valid_values]
            )
          end
        end

        def present?(key)
          param = param_for(key)

          return false unless param

          param.value.present?
        end

        def set(key, value)
          param = param_for(key)

          return "`#{key}` parameter is not supported" unless param

          param.set(value)
        end

        private

        attr_reader :parameters

        def param_for(key)
          parameters.find { |param| param.key == key }
        end
      end
    end
  end
end
