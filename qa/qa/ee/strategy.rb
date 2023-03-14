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
      end
    end
  end
end
