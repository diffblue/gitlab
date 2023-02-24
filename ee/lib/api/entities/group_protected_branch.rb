# frozen_string_literal: true

module API
  module Entities
    class GroupProtectedBranch < ProtectedBranch
      unexpose :inherited
    end
  end
end
