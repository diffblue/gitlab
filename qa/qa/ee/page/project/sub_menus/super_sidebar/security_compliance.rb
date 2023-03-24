# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module SubMenus
          module SuperSidebar
            module SecurityCompliance
              extend QA::Page::PageConcern

              def go_to_security_dashboard
                open_security_compliance_submenu('Security dashboard')
              end

              def go_to_vulnerability_report
                open_security_compliance_submenu('Vulnerability report')
              end

              def go_to_dependency_list
                open_security_compliance_submenu('Dependency list')
              end

              def go_to_policies
                open_security_compliance_submenu('Policies')
              end

              def go_to_security_configuration
                open_security_compliance_submenu('Security configuration')
              end

              def go_to_audit_events
                open_security_compliance_submenu("Audit events")
              end

              private

              def open_security_compliance_submenu(sub_menu)
                open_submenu("Security and Compliance", "#security-and-compliance", sub_menu)
              end
            end
          end
        end
      end
    end
  end
end
