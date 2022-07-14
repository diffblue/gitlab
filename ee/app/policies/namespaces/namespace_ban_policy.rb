# frozen_string_literal: true

module Namespaces
  class NamespaceBanPolicy < BasePolicy
    delegate { @subject.namespace }
  end
end
