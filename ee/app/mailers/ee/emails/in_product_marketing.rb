# frozen_string_literal: true

module EE
  module Emails
    module InProductMarketing
      def account_validation_email(pipeline, recipient_email)
        @message = ::Gitlab::Email::Message::AccountValidation.new(pipeline)

        mail_to(to: recipient_email, subject: @message.subject_line)
      end
    end
  end
end
