# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module SubMenus
          module SuperSidebar
            module Manage
              extend QA::Page::PageConcern

              def go_to_group_iterations
                open_manage_submenu('Iterations')
              end
            end
          end
        end
      end
    end
  end
end
