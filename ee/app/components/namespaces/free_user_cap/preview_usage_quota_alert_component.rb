# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class PreviewUsageQuotaAlertComponent < ViewComponent::Base
      def initialize(namespace:, user:, content_class:)
        @namespace = namespace
        @user = user
        @content_class = content_class
      end

      def call
        alert_data = Shared.alert_data(feature_name: PREVIEW_USAGE_QUOTA_FREE_PLAN_ALERT, namespace: namespace)
        container_class = Shared.container_class(content_class)

        tag.div(class: container_class) do
          render Pajamas::AlertComponent.new(
            variant: :info,
            alert_options: { class: Namespaces::FreeUserCap::Shared::ALERT_CLASS, data: alert_data },
            title: Shared.preview_alert_title,
            close_button_options: { data: Shared.close_button_data }
          ) do |c|
            c.body { over_limit_message }
          end
        end
      end

      private

      PREVIEW_USAGE_QUOTA_FREE_PLAN_ALERT = 'preview_usage_quota_free_plan_alert'

      attr_reader :namespace, :user, :content_class

      def render?
        Shared.preview_render?(user: user, namespace: namespace, feature_name: PREVIEW_USAGE_QUOTA_FREE_PLAN_ALERT)
      end

      def over_limit_message
        # see issue with ViewComponent overriding Kernel version
        # https://github.com/github/view_component/issues/156#issuecomment-737469885
        Kernel.format(
          n_(
            'You can begin moving members in %{namespace_name} now. A member loses access to the group when ' \
            'you turn off %{strong_start}In a seat%{strong_end}. If over %{free_user_limit} member has ' \
            '%{strong_start}In a seat%{strong_end} enabled after October 19, 2022, we\'ll select the ' \
            '%{free_user_limit} member who maintains access. We\'ll first count members that have Owner and ' \
            'Maintainer roles, then the most recently active members until we reach %{free_user_limit} member. ' \
            'The remaining members will get a status of Over limit and lose access to the group.',
            'You can begin moving members in %{namespace_name} now. A member loses access to the group when ' \
            'you turn off %{strong_start}In a seat%{strong_end}. If over %{free_user_limit} members have ' \
            '%{strong_start}In a seat%{strong_end} enabled after October 19, 2022, we\'ll select the ' \
            '%{free_user_limit} members who maintain access. We\'ll first count members that have Owner and ' \
            'Maintainer roles, then the most recently active members until we reach %{free_user_limit} members. ' \
            'The remaining members will get a status of Over limit and lose access to the group.',
            Shared.free_user_limit
          ),
          strong_start: Shared.strong_start,
          strong_end: Shared.strong_end,
          namespace_name: namespace.name,
          free_user_limit: Shared.free_user_limit
        ).html_safe
      end
    end
  end
end
