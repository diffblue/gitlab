# frozen_string_literal: true

module Audit
  class UnauthenticatedSecurityEventAuditor
    def initialize(user, authentication_method = 'STANDARD')
      if user.instance_of?(String)
        @author = ::Gitlab::Audit::UnauthenticatedAuthor.new(name: user)
        @scope = Gitlab::Audit::InstanceScope.new
      else
        @author = @scope = user
      end

      @authentication_method = authentication_method
    end

    def execute
      context = {
        name: "login_failed_with_#{@authentication_method.downcase}_authentication",
        scope: @scope,
        author: @author,
        target: @author,
        message: "Failed to login with #{@authentication_method} authentication",
        additional_details: {
          failed_login: @authentication_method
        }
      }

      ::Gitlab::Audit::Auditor.audit(context)
    end
  end
end
