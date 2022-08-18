# frozen_string_literal: true

module EE
  module Groups
    module Settings
      module RepositoryController
        extend ::Gitlab::Utils::Override
        extend ActiveSupport::Concern

        prepended do
          before_action :define_push_rule_variable, if: -> { can?(current_user, :change_push_rules, group) }
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
      end
    end
  end
end
