# frozen_string_literal: true

module Admin
  module LicenseRequest
    private

    def license
      @license ||= begin
        License.reset_current
        License.reset_future_dated
        License.current
      end
    end

    def require_license
      return if license

      flash.keep
      redirect_to general_admin_application_settings_path
    end
  end
end
