# frozen_string_literal: true
module Vulnerabilities
  class FindingPolicy < BasePolicy
    delegate { @subject.project }

    rule { ~can?(:read_security_resource) }.prevent :create_note
  end
end
