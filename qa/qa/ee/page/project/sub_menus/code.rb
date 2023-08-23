# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module SubMenus
          module Code
            extend QA::Page::PageConcern

            def go_to_repository_locked_files
              open_code_submenu('Locked files')
            end
          end
        end
      end
    end
  end
end
