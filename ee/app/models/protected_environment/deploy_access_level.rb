# frozen_string_literal: true
class ProtectedEnvironment::DeployAccessLevel < ApplicationRecord
  include ProtectedEnvironments::Authorizable

  belongs_to :protected_environment, inverse_of: :deploy_access_levels

  validates :access_level, presence: true, inclusion: { in: ALLOWED_ACCESS_LEVELS }
end
