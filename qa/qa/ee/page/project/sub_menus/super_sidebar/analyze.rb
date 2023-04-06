# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module SubMenus
          module SuperSidebar
            module Analyze
              extend QA::Page::PageConcern

              def self.prepended(base)
                super

                base.class_eval do
                  prepend Page::SubMenus::SuperSidebar::Analyze
                end
              end

              def go_to_value_stream_analytics
                open_analyze_submenu('Value stream analytics')
              end

              def go_to_contributor_statistics
                open_analyze_submenu('Contributor statistics')
              end

              def go_to_code_review_analytics
                open_analyze_submenu('Code review analytics')
              end

              def go_to_merge_request_analytics
                open_analyze_submenu('Merge request analytics')
              end
            end
          end
        end
      end
    end
  end
end
