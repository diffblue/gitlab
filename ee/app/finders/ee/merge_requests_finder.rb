# frozen_string_literal: true

module EE
  module MergeRequestsFinder
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    override :filter_items
    def filter_items(items)
      items = super(items)
      items = by_approvers(items)
      by_merge_commit_sha(items)
    end

    override :by_approved
    def by_approved(items)
      approved_param = ::Gitlab::Utils.to_boolean(params.fetch(:approved, nil))
      return items if approved_param.nil? || ::Feature.disabled?(:mr_approved_filter, type: :ops)

      approved_filter = ->(item) {
        if item.approval_needed?
          item.approved?
        else
          item.total_approvals_count > 0
        end
      }

      # rubocop: disable CodeReuse/ActiveRecord
      preload_items = items.preload(
        :approvers,
        :approval_merge_request_rule_sources,
        :approvals,
        target_project: [
          :approval_rules,
          :regular_or_any_approver_approval_rules,
          { group: :group_merge_request_approval_setting }
        ]
      )

      filtered_items = if approved_param
                         preload_items.select(&approved_filter)
                       else
                         preload_items.reject(&approved_filter)
                       end

      ::MergeRequest.where(id: filtered_items.pluck(:id))
      # rubocop: enable CodeReuse/ActiveRecord
    end

    # Filter by merge requests approval list that contains specified user directly or as part of group membership
    def by_approvers(items)
      ::MergeRequests::ByApproversFinder
        .new(params[:approver_usernames], params[:approver_ids])
        .execute(items)
    end

    def by_merge_commit_sha(items)
      return items unless params[:merge_commit_sha].present?

      items.by_merge_commit_sha(params[:merge_commit_sha])
    end

    override :use_grouping_columns?
    def use_grouping_columns?
      return false unless params[:sort].present?

      super || params[:approver_usernames].present? || params[:approver_ids].present?
    end

    class_methods do
      extend ::Gitlab::Utils::Override

      override :scalar_params
      def scalar_params
        @scalar_params ||= super + [:approver_ids]
      end

      override :array_params
      def array_params
        @array_params ||= super.merge(approver_usernames: [])
      end
    end
  end
end
