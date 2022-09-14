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
