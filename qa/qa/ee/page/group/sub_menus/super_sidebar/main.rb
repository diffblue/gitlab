# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module SubMenus
          module SuperSidebar
            module Main
              extend QA::Page::PageConcern

              def go_to_epics
                click_element(:nav_item_link, submenu_item: 'Epics')
              end
            end
          end
        end
      end
    end
  end
end
