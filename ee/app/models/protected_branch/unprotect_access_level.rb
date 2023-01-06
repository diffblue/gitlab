# frozen_string_literal: true

class ProtectedBranch::UnprotectAccessLevel < ApplicationRecord
  include Importable
  include ProtectedBranchAccess
end
