# frozen_string_literal: true

module EE
  module EmailsHelper
    extend ::Gitlab::Utils::Override

    override :action_title
    def action_title(url)
      return "View Epic" if url.split("/").include?('epics')

      super
    end

    override :service_desk_email_additional_text
    def service_desk_email_additional_text
      return unless ::Gitlab::CurrentSettings.email_additional_text.present?

      ::Gitlab::CurrentSettings.email_additional_text
    end
  end
end
