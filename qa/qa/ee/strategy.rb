# frozen_string_literal: true

module QA
  module EE
    module Strategy
      extend self

      def perform_before_hooks
        QA::CE::Strategy.perform_before_hooks
        return unless QA::Runtime::Env.ee_license.present?

        QA::Runtime::Logger.info("Performing initial license fabrication!")
        QA::Page::Main::Menu.perform(&:sign_out_if_signed_in)

        EE::Resource::License.fabricate! do |resource|
          resource.license = QA::Runtime::Env.ee_license
        end

        unless QA::Runtime::Env.running_on_dot_com?
          QA::Runtime::Logger.info("Disabling sync with External package metadata database")
          QA::Runtime::ApplicationSettings.set_application_settings(package_metadata_purl_types: [12])
        end

        QA::Page::Main::Menu.perform(&:sign_out_if_signed_in)
      end
    end
  end
end
