# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    module Projects
      class UsageQuotaLimitationsBannerPresenter < Gitlab::View::Presenter::Simple
        # Expects a current_user to also be provided in order for the `dismissed?` functionality to work. For example:
        #
        # Namespaces::Projects::UsageQuotaLimitationsBannerPresenter.new(
        #   @project,
        #   current_user: current_user
        # )
        presents Project, as: :project

        def feature_name
          'personal_project_limitations_banner'
        end

        def visible?
          free_user_cap_enforced? &&
            non_group_project? &&
            user_owns_namespace? &&
            !dismissed?
        end

        def dismissed?
          current_user.dismissed_callout?(feature_name: feature_name)
        end

        def alert_component_attributes
          {
            alert_options: {
              class: 'js-project-usage-limitations-callout gl-mt-4 gl-mb-5',
              data: {
                dismiss_endpoint: callouts_path,
                feature_id: feature_name
              }
            },
            title: title_text,
            variant: :tip
          }
        end

        def title_text
          _('Your project has limited quotas and features')
        end

        def body_text
          move_to_group_url = help_page_path('tutorials/move_personal_project_to_a_group')
          manage_members_url = project_project_members_path(project)
          namespace = project.namespace.root_ancestor

          _(
            '%{strong_start}%{project_name}%{strong_end} is a personal project, ' \
            'so you can’t upgrade to a paid plan or start a free trial to lift these limits. ' \
            'We recommend %{move_to_group_link}moving this project to a group%{end_link} to unlock these options. ' \
            'You can %{manage_members_link}manage the members of this project%{end_link}, ' \
            'but don’t forget that all unique members in your personal namespace ' \
            '%{strong_start}%{namespace_name}%{strong_end} count towards total seats in use.'
          ).html_safe % {
            strong_start: '<strong>'.html_safe,
            strong_end: '</strong>'.html_safe,
            end_link: '</a>'.html_safe,
            move_to_group_link: '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % {
              url: move_to_group_url
            },
            manage_members_link: '<a href="%{url}">'.html_safe % { url: manage_members_url },
            project_name: project.name,
            namespace_name: namespace.name
          }
        end

        private

        def non_group_project?
          project.group.nil?
        end

        def free_user_cap_enforced?
          ::Namespaces::FreeUserCap::Standard.new(project.namespace).enforce_cap?
        end

        def user_owns_namespace?
          Ability.allowed?(current_user, :owner_access, project.namespace)
        end
      end
    end
  end
end
