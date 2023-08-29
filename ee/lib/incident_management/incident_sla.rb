# frozen_string_literal: true

module IncidentManagement
  module IncidentSla
    class << self
      def available_for?(licensed_object)
        licensed_object.licensed_feature_available?(:incident_sla)
      end
    end
  end
end
