# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module SubMenus
          module LicenseCompliance
            extend QA::Page::PageConcern

            def go_to_license_compliance
              hover_security_compliance do
                within_submenu do
                  click_element(:sidebar_menu_item_link, menu_item: 'License compliance')
                end
              end
            end

            def hover_security_compliance
              within_sidebar do
                find_element(:sidebar_menu_link, menu_item: 'Security and Compliance').hover

                yield
              end
            end
          end
        end
      end
    end
  end
end
