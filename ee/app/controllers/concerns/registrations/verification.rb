# frozen_string_literal: true

module Registrations::Verification
  extend ActiveSupport::Concern

  included do
    before_action :require_verification, if: :verification_required?

    private

    def verification_required?
      html_request? &&
        request.get? &&
        current_user&.requires_credit_card_verification
    end

    def require_verification
      redirect_to new_users_sign_up_groups_project_path
    end

    def set_requires_verification
      ::Users::UpdateService.new(current_user, user: current_user, requires_credit_card_verification: true).execute!
    end
  end
end
