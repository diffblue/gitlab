# frozen_string_literal: true

module EE
  module Types
    module Projects
      module BranchRuleType
        extend ActiveSupport::Concern

        prepended do
          field :approval_rules,
                type: ::Types::BranchRules::ApprovalProjectRuleType.connection_type,
                method: :approval_project_rules,
                null: true,
                description: 'Merge request approval rules configured for this branch rule.'
        end
      end
    end
  end
end
