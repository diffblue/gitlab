# frozen_string_literal: true

module GitlabSubscriptions
  class AddOnPurchasePolicy < ::BasePolicy
    delegate { subject.namespace }
  end
end
