# frozen_string_literal: true

module EE
  module Emails
    module BaseService
      private

      def log_audit_event(options = {})
        audit_context = case options[:action]
                        when :create
                          {
                            name: "email_created",
                            message: "Email created",
                            additional_details: { add: "email" }
                          }
                        when :destroy
                          {
                            name: "email_destroyed",
                            message: "Email destroyed",
                            additional_details: { remove: "email" }
                          }
                        when :confirm
                          {
                            name: "email_confirmation_sent",
                            message: "Confirmation instructions sent to: #{options[:unconfirmed_email]}",
                            additional_details: {
                              current_email: @current_user.email,
                              target_type: "Email",
                              unconfirmed_email: options[:unconfirmed_email]
                            }
                          }
                        end

        ::Gitlab::Audit::Auditor.audit(audit_context.deep_merge({
          author: @current_user,
          scope: @user,
          target: options[:target],
          additional_details: {
            author_name: @current_user.name,
            target_type: "Email"
          }
        }))
      end
    end
  end
end
