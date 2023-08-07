# frozen_string_literal: true

# Validates CVSS vector strings.
# Works for CVSS 3.1, 3.0, and 2.0
module Vulnerabilities
  class CvssVectorValidator < ActiveModel::EachValidator
    VALIDATIONS = %i[
      validate_type
      validate_vector
      validate_version
    ].freeze

    def validate_each(record, attribute, value)
      VALIDATIONS.all? do |method|
        method.to_proc.call(self, record, attribute, value)
      end
    end

    def validate_type(record, attribute, value)
      return true if value.is_a?(::CvssSuite::Cvss)

      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
        ArgumentError.new("expected #{attribute} to be a ::CvssSuite::Cvss but was #{value.class}")
      )

      record.errors.add(attribute, "cannot be validated due to an unexpected internal state")

      false
    end

    def validate_vector(record, attribute, value)
      return true if value.valid?

      record.errors.add(attribute, "is not a valid CVSS vector string")

      false
    end

    def validate_version(record, attribute, value)
      return true unless allowed_versions = options[:allowed_versions]
      return true if allowed_versions.include?(value.version)

      version_list = allowed_versions.join(' or ')
      record.errors.add(attribute, "must use version #{version_list}")

      false
    end
  end
end
