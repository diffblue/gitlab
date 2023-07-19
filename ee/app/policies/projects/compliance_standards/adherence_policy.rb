# frozen_string_literal: true

module Projects
  module ComplianceStandards
    class AdherencePolicy < BasePolicy
      delegate { @subject.namespace }
    end
  end
end
