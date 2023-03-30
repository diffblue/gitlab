# frozen_string_literal: true

module EE
  module FeatureGroups
    module GitlabTeamMembers
      extend ActiveSupport::Concern

      class_methods do
        extend ::Gitlab::Utils::Override

        override :enabled?
        def enabled?(thing)
          thing.is_a?(::User) && ::Gitlab::Com.gitlab_com_group_member?(thing.id)
        end
      end
    end
  end
end
