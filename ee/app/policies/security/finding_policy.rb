# frozen_string_literal: true
module Security
  class FindingPolicy < BasePolicy
    delegate { @subject.scan }

    rule { ~can?(:read_security_resource) }
  end
end
