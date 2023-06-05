# frozen_string_literal: true

module Gitlab
  module Audit
    module Levels
      class Group
        def initialize(group:)
          @group = group
        end

        def apply
          if Feature.enabled?(:audit_event_group_rollup, @group)
            AuditEvent.by_group(@group)
          else
            AuditEvent.by_entity('Group', @group)
          end
        end
      end
    end
  end
end
