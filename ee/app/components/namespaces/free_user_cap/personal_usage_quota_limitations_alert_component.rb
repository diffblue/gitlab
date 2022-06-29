# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class PersonalUsageQuotaLimitationsAlertComponent < ViewComponent::Base
      include Personable

      USER_CALLOUT_FEATURE_NAME = 'personal_project_limitations_banner'
      JS_PERSISTENT_USER_CALLOUT_IDENTIFIER = 'js-project-usage-limitations-callout'

      def initialize(project:, user:)
        @project = project
        @namespace = project.root_namespace
        @user = user
      end

      def title_text
        _('Your project has limited quotas and features')
      end

      def body_text
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
          move_to_group_link: move_link_start,
          manage_members_link: '<a href="%{url}">'.html_safe % { url: manage_members_url },
          project_name: @project.name,
          namespace_name: @namespace.name
        }
      end

      def variant
        :tip
      end

      def alert_options
        {
          class: "#{JS_PERSISTENT_USER_CALLOUT_IDENTIFIER} gl-mt-4 gl-mb-5",
          data: alert_data
        }
      end

      private

      attr_reader :user

      def base_alert_data
        { feature_id: feature_name }
      end

      def manage_members_url
        project_project_members_path(@project)
      end

      def render?
        @namespace.user_namespace? &&
          user_owns_namespace? &&
          free_user_cap_enforced? &&
          !dismissed?
      end

      def free_user_cap_enforced?
        ::Namespaces::FreeUserCap::Standard.new(@namespace).enforce_cap?
      end

      def user_owns_namespace?
        Ability.allowed?(user, :owner_access, @namespace)
      end

      def feature_name
        USER_CALLOUT_FEATURE_NAME
      end

      def ignore_dismissal_earlier_than
        nil
      end
    end
  end
end
