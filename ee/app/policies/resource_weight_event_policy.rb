# frozen_string_literal: true

class ResourceWeightEventPolicy < ResourceEventPolicy
  rule { can_read_issuable }.policy do
    enable :read_resource_weight_event
    enable :read_note
  end
end
