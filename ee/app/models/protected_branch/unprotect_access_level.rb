# frozen_string_literal: true

class ProtectedBranch::UnprotectAccessLevel < ApplicationRecord
  include Importable

  # Override `ProtectedBranchAccess::allowed_access_levels` method:
  #
  # UnprotectAccessLevels define rules around who can delete a ProtectedBranch
  # record.
  #
  # Remove NO_ACCESS option for UnprotectAccessLevel to prevent
  # creating ProtectedBranches which can not be unprotected by any user.
  # See: https://gitlab.com/gitlab-org/gitlab/-/issues/345277
  #
  # NOTE: This method must be defined before we `include ProtectedBranchAccess`
  # because the validator is configured at the moment the module is included
  # (see ProtectedRefAccess module):
  #
  #  included do
  #    #...
  #    `validate :access_level, inclusion: { in: { allowed_access_levels`
  #    #                                           ^ method is called here
  #  end
  #
  # If `include` comes before the method defined here, ruby is currently not
  # aware of this method definition so instead calls directly to the
  # allowed_access_levels method defined in the ProtectedRefAccess module.
  def self.allowed_access_levels
    super.excluding(Gitlab::Access::NO_ACCESS)
  end
  include ProtectedBranchAccess
end
