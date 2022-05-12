# frozen_string_literal: true

module Namespaces
  class PreviewFreeUserCapAlertComponent < ViewComponent::Base
    # @param [Namespace or Group] namespace
    # @param [User] user
    # @param [String] content_class
    def initialize(namespace:, user:, content_class:)
      @namespace = namespace
      @user = user
      @content_class = content_class
    end

    private

    PREVIEW_USER_OVER_LIMIT_FREE_PLAN_ALERT = 'preview_user_over_limit_free_plan_alert'
    BLOG_URL = 'https://about.gitlab.com/blog/2022/03/24/efficient-free-tier'
    IGNORE_DISMISSAL_EARLIER_THAN = 14.days.ago

    attr_reader :namespace, :user, :content_class

    def render?
      return false unless user
      return false if preview_dismissed?
      return false unless Ability.allowed?(user, :owner_access, namespace)

      ::Namespaces::PreviewFreeUserCap.new(namespace).over_limit?
    end

    def preview_dismissed?
      if namespace.user_namespace?
        user.dismissed_callout?(feature_name: PREVIEW_USER_OVER_LIMIT_FREE_PLAN_ALERT,
                                ignore_dismissal_earlier_than: IGNORE_DISMISSAL_EARLIER_THAN)
      else
        user.dismissed_callout_for_group?(feature_name: PREVIEW_USER_OVER_LIMIT_FREE_PLAN_ALERT,
                                          group: namespace,
                                          ignore_dismissal_earlier_than: IGNORE_DISMISSAL_EARLIER_THAN)
      end
    end

    def alert_data
      base_data = {
        track_action: 'render',
        track_label: 'user_limit_banner',
        feature_id: PREVIEW_USER_OVER_LIMIT_FREE_PLAN_ALERT,
        testid: 'user-over-limit-free-plan-alert'
      }

      if namespace.user_namespace?
        base_data.merge(dismiss_endpoint: callouts_path)
      else
        base_data.merge(dismiss_endpoint: group_callouts_path, group_id: namespace.id)
      end
    end

    def close_button_data
      {
        track_action: 'dismiss_banner',
        track_label: 'user_limit_banner',
        testid: 'user-over-limit-free-plan-dismiss'
      }
    end

    def alert_attributes
      link_end = '</a>'.html_safe

      if namespace.user_namespace?
        {
          title: _('From June 22, 2022 (GitLab 15.1), you can have a maximum of %{free_limit} unique members ' \
                 'across all of your personal projects') % { free_limit: ::Namespaces::FreeUserCap::FREE_USER_LIMIT },
          body: _('You currently have more than %{free_limit} members across all your personal projects. ' \
                'From June 22, 2022, the %{free_limit} most recently active members will remain active, ' \
                'and the remaining members will get a %{link_start}status of Over limit%{link_end} and lose access. ' \
                'To view and manage members, check the members page for each project in your namespace. ' \
                'We recommend you %{move_link_start}move your project to a group%{move_link_end} so you can easily ' \
                'manage users and features.').html_safe % {
            free_limit: ::Namespaces::FreeUserCap::FREE_USER_LIMIT,
            link_start: '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: BLOG_URL },
            link_end: link_end,
            move_link_start: '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % {
              url: help_page_path('user/project/settings/index',
                                  anchor: 'transferring-an-existing-project-into-another-namespace')
            },
            move_link_end: link_end
          },
          primary_cta: (link_to _('View all personal projects'),
                                user_projects_path(user.username),
                                class: 'btn gl-alert-action btn-info btn-md gl-button',
                                data: {
                                  track_action: 'click_button',
                                  track_label: 'view_personal_projects',
                                  testid: 'user-over-limit-primary-cta'
                                })
        }
      else
        {
          title: _('From June 22, 2022 (GitLab 15.1), free personal namespaces and top-level groups will be limited ' \
                 'to %{free_limit} members') % { free_limit: ::Namespaces::FreeUserCap::FREE_USER_LIMIT },
          body: _('Your %{doc_link_start}namespace%{doc_link_end}, %{strong_start}%{namespace_name}%{strong_end} ' \
                'has more than %{free_limit} members. From June 22, 2022, it will be limited to %{free_limit}, ' \
                'and the remaining members will get a %{link_start}status of Over limit%{link_end} and lose ' \
                'access to the namespace. You can go to the Usage Quotas page to manage which %{free_limit} ' \
                'members will remain in your namespace. To get more members, an owner can start a trial or upgrade ' \
                'to a paid tier.').html_safe % {
            namespace_name: namespace.name,
            free_limit: ::Namespaces::FreeUserCap::FREE_USER_LIMIT,
            doc_link_start: '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % {
              url: help_page_path('user/group/index', anchor: 'namespaces')
            },
            doc_link_end: link_end,
            strong_start: "<strong>".html_safe,
            strong_end: "</strong>".html_safe,
            link_start: '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: BLOG_URL },
            link_end: link_end
          },
          primary_cta: (link_to _('Manage members'),
                                group_usage_quotas_path(namespace),
                                class: 'btn gl-alert-action btn-info btn-md gl-button',
                                data: {
                                  track_action: 'click_button',
                                  track_label: 'manage_members',
                                  testid: 'user-over-limit-primary-cta'
                                }),
          secondary_cta: (link_to _('Explore paid plans'),
                                  group_billings_path(namespace),
                                  class: 'btn gl-alert-action btn-default btn-md gl-button',
                                  data: { track_action: 'click_button',
                                          track_label: 'explore_paid_plans',
                                          testid: 'user-over-limit-secondary-cta' })
        }
      end
    end
  end
end
