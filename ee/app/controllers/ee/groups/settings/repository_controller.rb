# frozen_string_literal: true

module EE
  module Groups
    module Settings
      module RepositoryController
        extend ::Gitlab::Utils::Override
        extend ActiveSupport::Concern

        prepended do
          before_action :define_push_rule_variable, if: -> { can?(current_user, :change_push_rules, group) }
          before_action :define_protected_branches, only: [:show]
        end

        private

        override :authorize_access!
        def authorize_access!
          render_404 unless can?(current_user, :admin_group, group) || can?(current_user, :change_push_rules, group)
        end

        def define_push_rule_variable
          strong_memoize(:push_rule) do
            group.push_rule || group.build_push_rule
          end
        end

        # rubocop:disable Gitlab/ModuleWithInstanceVariables
        # rubocop:disable CodeReuse/ActiveRecord
        def define_protected_branches
          @protected_branches = group.protected_branches.order(:name).page(params[:page])
          @protected_branch = group.protected_branches.new
          gon.push(access_levels_options)
        end
        # rubocop:enable Gitlab/ModuleWithInstanceVariables
        # rubocop:enable CodeReuse/ActiveRecord

        def access_levels_options
          {
            create_access_levels: levels_for_dropdown,
            push_access_levels: levels_for_dropdown,
            merge_access_levels: levels_for_dropdown
          }
        end

        def levels_for_dropdown
          roles = ::ProtectedRef::AccessLevel.human_access_levels.map do |id, text|
            { id: id, text: text, before_divider: true }
          end

          { roles: roles }
        end
      end
    end
  end
end
