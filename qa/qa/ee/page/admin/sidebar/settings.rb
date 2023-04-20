# frozen_string_literal: true

module QA
  module EE
    module Page
      module Admin
        module Sidebar
          module Settings
            def go_to_template_settings
              open_settings_submenu("Templates")
            end
          end
        end
      end
    end
  end
end
