# frozen_string_literal: true

module ApprovalRules
  class BaseService < ::BaseService
    def execute
      return error(['Prohibited'], 403) unless can_edit?

      action
    end

    private

    def action
      raise 'Not implemented'
    end

    attr_reader :rule

    def can_edit?
      skip_authorization || can?(current_user, :edit_approval_rule, rule)
    end

    def skip_authorization
      @skip_authorization ||= params&.delete(:skip_authorization)
    end

    def success(*args, &blk)
      super.tap { |hsh| hsh[:rule] = rule }
    end

    def merge_request_activity_counter
      Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter
    end
  end
end
