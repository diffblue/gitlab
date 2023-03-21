# frozen_string_literal: true

module Vulnerabilities
  class BaseStateTransitionService < BaseService
    def initialize(user, vulnerability, comment)
      super(user, vulnerability)
      @comment = comment
    end

    def execute
      raise Gitlab::Access::AccessDeniedError unless authorized?

      if can_transition?
        ApplicationRecord.transaction do
          Vulnerabilities::StateTransition.create!(
            vulnerability: @vulnerability,
            from_state: @vulnerability.state,
            to_state: to_state,
            author: @user,
            comment: @comment
          )

          update_vulnerability!
        end
      end

      @vulnerability
    end
  end
end
