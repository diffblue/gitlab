# frozen_string_literal: true

module Gitlab
  module Audit
    module Levels
      class Group
        def initialize(group:)
          @group = group
        end

        def apply
          AuditEvent.by_entity('Group', @group)
        end
      end
    end
  end
end
