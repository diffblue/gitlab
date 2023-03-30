# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module SubMenus
          module SuperSidebar
            module Plan
              def go_to_issue_board
                open_plan_submenu("Issue board")
              end

              private

              def open_plan_submenu(sub_menu)
                open_submenu("Plan", "#plan", sub_menu)
              end
            end
          end
        end
      end
    end
  end
end
