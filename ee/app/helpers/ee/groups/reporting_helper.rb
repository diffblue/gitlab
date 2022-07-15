# frozen_string_literal: true

module EE
  module Groups
    module ReportingHelper
      def numericality_validation_options(obj, attr)
        validator = obj.class.validators_on(attr).find { |v| v.kind == :numericality }
        return {} unless validator

        min = validator.options[:greater_than] ||
              validator.options[:greater_than_or_equal_to] ||
              validator.options[:in]&.min
        max = validator.options[:less_than] ||
              validator.options[:less_than_or_equal_to] ||
              validator.options[:in]&.max
        return {} unless min && max

        error_message = _('%{attribute} must be between %{min} and %{max}') % {
          attribute: obj.class.human_attribute_name(attr), min: min, max: max
        }

        { min: min, max: max, title: error_message }
      end
    end
  end
end
