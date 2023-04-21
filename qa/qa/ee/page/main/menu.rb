# frozen_string_literal: true

module QA
  module EE
    module Page
      module Main
        module Menu
          def go_to_operations
            return click_element(:nav_item_link, submenu_item: 'Operations') if QA::Runtime::Env.super_sidebar_enabled?

            go_to_menu_dropdown_option(:operations_link)
          end
        end
      end
    end
  end
end
