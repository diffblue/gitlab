# frozen_string_literal: true

module EE
  module Resolvers
    module Projects
      module BranchRulesResolver
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override
        include ::Gitlab::Utils::StrongMemoize

        override :resolve_with_lookahead
        def resolve_with_lookahead(**args)
          super.tap do |rules|
            rules.unshift(all_protected_branches_rule) if all_protected_branches_rule.any_rules?
            rules.unshift(all_branches_rule) if all_branches_rule.any_rules?
          end
        end

        private

        # BranchRules for 'All branches' i.e. no associated ProtectedBranch
        def all_branches_rule
          ::Projects::AllBranchesRule.new(project)
        end
        strong_memoize_attr :all_branches_rule

        def all_protected_branches_rule
          ::Projects::AllProtectedBranchesRule.new(project)
        end
        strong_memoize_attr :all_protected_branches_rule

        override :preloads
        def preloads
          super.merge(
            approval_rules: { approval_project_rules: [:users, :group_users] },
            external_status_checks: :external_status_checks
          )
        end

        override :nested_preloads
        def nested_preloads
          super.deep_merge(branch_protection: branch_protection_preloads)
        end

        def branch_protection_preloads
          {
            merge_access_levels: access_levels_preloads_for(:merge),
            push_access_levels: access_levels_preloads_for(:push),
            unprotect_access_levels: access_levels_preloads_for(:unprotect)
          }
        end

        def access_levels_preloads_for(access_type)
          access_level_name = "#{access_type}_access_levels".to_sym
          access_levels_lookahead = access_levels_node_selection(access_level_name)

          preloads = []
          preloads << { group: group_preloads(access_levels_lookahead) } if access_levels_lookahead.selects?(:group)
          preloads << { user: user_preloads(access_levels_lookahead) } if access_levels_lookahead.selects?(:user)

          { access_level_name => preloads }
        end

        def group_preloads(access_levels_lookahead)
          preloads = [:saml_provider, :route]
          return preloads unless access_levels_lookahead.selection(:group).selects?(:parent)

          preloads << { parent: preloads.dup }
        end

        def user_preloads(access_levels_lookahead)
          # groups and projects are accessed in HasUserType#redacted_name
          return [] unless access_levels_lookahead.selection(:user).selects?(:name)

          %i[groups projects]
        end

        def access_levels_node_selection(access_level_name)
          access_levels_selection = node_selection
            .selection(:branch_protection)
            .selection(access_level_name)

          node_selection(access_levels_selection)
        end
      end
    end
  end
end
