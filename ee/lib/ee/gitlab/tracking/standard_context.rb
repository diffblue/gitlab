# frozen_string_literal: true

module EE
  module Gitlab
    module Tracking
      module StandardContext
        extend ::Gitlab::Utils::Override

        override :gitlab_team_member?
        def gitlab_team_member?(user_id)
          return unless ::Gitlab.com?
          return unless user_id

          ::Gitlab::Com.gitlab_com_group_member?(user_id)
        end
      end
    end
  end
end
