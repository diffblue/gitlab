# frozen_string_literal: true

module QA
  module EE
    module Strategy
      extend self

      def perform_before_hooks
        # Without a license, perform the CE before hooks only.
        unless ENV['EE_LICENSE'].present?
          QA::CE::Strategy.perform_before_hooks
          return
        end

        QA::Support::Retrier.retry_on_exception do
          QA::Runtime::Browser.visit(:gitlab, QA::Page::Main::Login)
        end

        QA::Support::Retrier.retry_on_exception do
          QA::Page::Main::Menu.perform(&:sign_out_if_signed_in)

          EE::Resource::License.fabricate!(ENV['EE_LICENSE'])
        end
      end
    end
  end
end
