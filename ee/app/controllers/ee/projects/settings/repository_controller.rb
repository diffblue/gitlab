# frozen_string_literal: true

module EE
  module Projects
    module Settings
      module RepositoryController
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        prepended do
          before_action :push_rule, only: [:show, :create_deploy_token]
        end

        private

        def push_rule
          return unless project.feature_available?(:push_rules)

          unless project.push_rule
            push_rule = project.create_push_rule
            project.project_setting.update(push_rule_id: push_rule.id)
          end

          @push_rule = project.push_rule # rubocop:disable Gitlab/ModuleWithInstanceVariables
        end

        # rubocop:disable Gitlab/ModuleWithInstanceVariables
        override :access_levels_options
        def access_levels_options
          super.merge(
            selected_merge_access_levels: @protected_branch.merge_access_levels.map { |access_level| access_level.user_id || access_level.access_level },
            selected_push_access_levels: @protected_branch.push_access_levels.map { |access_level| access_level.user_id || access_level.access_level },
            selected_create_access_levels: @protected_tag.create_access_levels.map { |access_level| access_level.user_id || access_level.access_level }
          )
        end
        # rubocop:enable Gitlab/ModuleWithInstanceVariables

        def render_show
          push_rule

          super
        end

        override :fetch_protected_branches
        def fetch_protected_branches(project)
          return super unless group_protected_branches_feature_available?

          project.all_protected_branches.sorted_by_namespace_and_name.page(params[:page])
        end

        def group_protected_branches_feature_available?
          ::Feature.enabled?(:group_protected_branches) &&
            ::License.feature_available?(:group_protected_branches)
        end
      end
    end
  end
end
