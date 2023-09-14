# frozen_string_literal: true

module GitlabSubscriptions
  class UserAddOnAssignmentPolicy < ::BasePolicy
    delegate { subject.add_on_purchase }
  end
end
