# frozen_string_literal: true

module EE
  module Resolvers
    module Projects
      module BranchRulesResolver
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        private

        override :preloads
        def preloads
          super.merge({
                        approval_rules: {
                          approval_project_rules: [:users, :group_users]
                        }
                      })
        end
      end
    end
  end
end
