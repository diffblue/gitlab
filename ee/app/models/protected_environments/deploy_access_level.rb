# frozen_string_literal: true

module ProtectedEnvironments
  class DeployAccessLevel < ApplicationRecord
    include Authorizable

    self.table_name = 'protected_environment_deploy_access_levels'

    belongs_to :protected_environment, inverse_of: :deploy_access_levels

    validates :access_level, allow_blank: true, inclusion: { in: ALLOWED_ACCESS_LEVELS }
    validates :group_inheritance_type, inclusion: { in: GROUP_INHERITANCE_TYPE.values }
    validate :authorizable_attributes_presence

    # `access_level` column has `DEFAULT 40`, therefore it sets the default value even if it's user-base or group-base
    # authorization, however, this value should be NULL in these cases.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/330483 for more information.
    def access_level
      super if role?
    end

    def authorizable_attributes_presence
      unless read_attribute(:access_level) || read_attribute(:group_id) || read_attribute(:user_id)
        errors.add(:base, 'One of the Group ID, User ID or Access Level must be specified.')
      end
    end
  end
end
