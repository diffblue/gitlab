# frozen_string_literal: true

module EE
  module ProjectAuthorization
    extend ActiveSupport::Concern

    prepended do
      scope :eligible_approvers_by_project_id_and_access_levels, ->(project_id, access_levels) do
        where(project_id: project_id, access_level: access_levels)
          .limit(Security::ScanResultPolicy::APPROVERS_LIMIT)
      end
    end

    class_methods do
      def visible_to_user_and_access_level(user, access_level)
        where(user: user).where('access_level >= ?', access_level)
      end

      def pluck_user_ids
        pluck(:user_id)
      end
    end
  end
end
