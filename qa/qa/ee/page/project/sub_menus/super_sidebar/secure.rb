# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module SubMenus
          module SuperSidebar
            module Secure
              extend QA::Page::PageConcern

              def go_to_security_dashboard
                open_secure_submenu('Security dashboard')
              end

              def go_to_vulnerability_report
                open_secure_submenu('Vulnerability report')
              end

              def go_to_dependency_list
                open_secure_submenu('Dependency list')
              end

              def go_to_policies
                open_secure_submenu('Policies')
              end

              def go_to_security_configuration
                open_secure_submenu('Security configuration')
              end

              def go_to_audit_events
                open_secure_submenu("Audit events")
              end
            end
          end
        end
      end
    end
  end
end
