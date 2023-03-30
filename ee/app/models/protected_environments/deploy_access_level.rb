# frozen_string_literal: true

module ProtectedEnvironments
  class DeployAccessLevel < ApplicationRecord
    include Authorizable

    self.table_name = 'protected_environment_deploy_access_levels'

    belongs_to :protected_environment, inverse_of: :deploy_access_levels

    validates :access_level, allow_blank: true, inclusion: { in: ALLOWED_ACCESS_LEVELS }
    validates :group_inheritance_type, inclusion: { in: GROUP_INHERITANCE_TYPE.values }
    validate :authorizable_attributes_presence

    def authorizable_attributes_presence
      return if [read_attribute(:access_level), read_attribute(:group_id), read_attribute(:user_id)].compact.count == 1

      errors.add(:base, 'Only one of the Group ID, User ID or Access Level must be specified.')
    end
  end
end
