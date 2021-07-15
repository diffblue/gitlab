# frozen_string_literal: true

module MergeRequests
  class SyncCodeOwnerApprovalRules
    AlreadyMergedError = Class.new(StandardError)

    def initialize(merge_request, params = {})
      @merge_request = merge_request
      @previous_diff = params[:previous_diff]
    end

    def execute
      return already_merged if merge_request.merged?

      delete_outdated_code_owner_rules

      existing_rules = merge_request.approval_rules.matching_pattern(patterns).to_a

      code_owner_entries.each do |entry|
        rule = existing_rules.detect { |rule| rule.name == entry.pattern }
        rule ||= create_rule(entry)

        rule.users = entry.users
        rule.groups = entry.groups

        rule.save
      end
    end

    private

    attr_reader :merge_request, :previous_diff

    def create_rule(entry)
      ApprovalMergeRequestRule.find_or_create_code_owner_rule(merge_request, entry)
    end

    def delete_outdated_code_owner_rules
      merge_request.approval_rules.not_matching_pattern(patterns).delete_all
    end

    def patterns
      @patterns ||= code_owner_entries.map(&:pattern)
    end

    def code_owner_entries
      @code_owner_entries ||= Gitlab::CodeOwners
                                .entries_for_merge_request(merge_request, merge_request_diff: previous_diff)
    end

    def already_merged
      Gitlab::ErrorTracking.track_exception(
        AlreadyMergedError.new('MR already merged before code owner approval rules were synced'),
        merge_request_id: merge_request.id,
        merge_request_iid: merge_request.iid,
        project_id: merge_request.project_id
      )
      nil
    end
  end
end
