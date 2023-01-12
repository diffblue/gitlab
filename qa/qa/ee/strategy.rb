# frozen_string_literal: true

module QA
  module EE
    module Strategy
      extend self

      def perform_before_hooks
        QA::CE::Strategy.perform_before_hooks
        return unless ENV['EE_LICENSE'].present?

        QA::Runtime::Logger.info("Performing initial license fabrication!")
        QA::Support::Retrier.retry_on_exception do
          QA::Page::Main::Menu.perform(&:sign_out_if_signed_in)

          EE::Resource::License.fabricate! do |resource|
            resource.license = ENV['EE_LICENSE']
          end
        end
      end
    end
  end
end
