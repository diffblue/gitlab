# frozen_string_literal: true

module PasswordComplexity
  extend ActiveSupport::Concern

  included do
    validates :password, 'password/complexity': true, if: :validate_password_complexity?
  end

  class_methods do
    private

    def complexity_matched?(password)
      return true unless License.feature_available?(:password_complexity)

      ::Password::ComplexityValidator.required_complexity_rules
        .all? do |regex, _error|
          regex.match?(password)
        end
    end
  end

  private

  def validate_password_complexity?
    password_required? && License.feature_available?(:password_complexity)
  end
end
