# frozen_string_literal: true

class ResourceIterationEventPolicy < ResourceEventPolicy
  condition(:can_read_iteration) { @subject.iteration_id.nil? || can?(:read_iteration, @subject.iteration) }

  rule { can_read_iteration }.policy do
    enable :read_iteration
  end

  rule { can_read_iteration & can_read_issuable }.policy do
    enable :read_resource_iteration_event
    enable :read_note
  end
end
