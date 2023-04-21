# frozen_string_literal: true

module QA
  module EE
    module Page
      module Admin
        module Sidebar
          module Monitoring
            def go_to_monitoring_audit_events
              open_monitoring_submenu("Audit Events")
            end

            private

            def open_monitoring_submenu(sub_menu)
              open_submenu("Monitoring", sub_menu)
            end
          end
        end
      end
    end
  end
end
