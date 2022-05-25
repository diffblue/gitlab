# frozen_string_literal: true

# Password::ComplexityValidator
#
# Validates that the password value matches password complexity settings
#
# @example Usage
#    class User < ApplicationRecord
#      validate :name, 'gitlab/password_complexity': true
#    end

module Password
  class ComplexityValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      self.class.required_complexity_rules.each do |regex, error|
        record.errors.add attribute, error unless regex.match?(value)
      end
    end

    def self.required_complexity_rules
      rules = []

      settings = Gitlab::CurrentSettings.current_application_settings

      if settings.password_number_required?
        rules << [/\p{N}/, s_('Password|requires at least one number')]
      end

      if settings.password_lowercase_required?
        rules << [/\p{Lower}/, s_('Password|requires at least one lowercase letter')]
      end

      if settings.password_uppercase_required?
        rules << [/\p{Upper}/, s_('Password|requires at least one uppercase letter')]
      end

      if settings.password_symbol_required?
        rules << [/[^\p{N}\p{Upper}\p{Lower}]/, s_('Password|requires at least one symbol character')]
      end

      rules
    end
  end
end
