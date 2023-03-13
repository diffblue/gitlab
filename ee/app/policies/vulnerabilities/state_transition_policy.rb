# frozen_string_literal: true

module Vulnerabilities
  class StateTransitionPolicy < BasePolicy
    delegate { @subject.vulnerability.project }

    rule { ~can?(:read_security_resource) }
  end
end
