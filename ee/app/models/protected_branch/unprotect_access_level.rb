# frozen_string_literal: true

class ProtectedBranch::UnprotectAccessLevel < ApplicationRecord
  include Importable
  include ProtectedBranchAccess

  # Remove no_access being option for UnprotectAccessLevel as it was
  # creating branches which could not be unprotected by any user,
  # see https://gitlab.com/gitlab-org/gitlab/-/issues/345277
  def self.allowed_access_levels
    [
      *super - [::Gitlab::Access::NO_ACCESS]
    ]
  end
end
