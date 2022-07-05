# frozen_string_literal: true

module EE
  module API
    module MergeRequests
      extend ActiveSupport::Concern

      prepended do
        helpers do
          params :optional_params_ee do
            optional :approvals_before_merge, type: Integer, desc: 'Number of approvals required before this can be merged'
            optional :approval_rules_attributes, type: Array, documentation: { hidden: true } do
              optional :id, type: Integer, desc: 'The ID of a rule'
              optional :approvals_required, type: Integer, desc: 'Total number of approvals required'
            end
          end

          params :optional_merge_requests_search_params do
            optional :approver_ids, types: [String, Array], array_none_any: true,
                     desc: 'Return merge requests which have specified the users with the given IDs as an individual approver'
            optional :approved_by_ids, types: [String, Array], array_none_any: true,
                     desc: 'Return merge requests which have been approved by the specified users with the given IDs'
            optional :approved_by_usernames, types: [String, Array], array_none_any: true,
                     desc: 'Return merge requests which have been approved by the specified users with the given
            usernames'
            mutually_exclusive :approved_by_ids, :approved_by_usernames
          end
        end
      end
    end
  end
end
