# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Snippet
          module Index
            extend QA::Page::PageConcern

            def wait_for_snippet_replication(title)
              QA::Runtime::Logger.debug(%[#{self.class.name} - wait_for_snippet_replication])
              wait_until(max_duration: Runtime::Geo.max_file_replication_time) do
                has_project_snippet?(title)
              end
            end
          end
        end
      end
    end
  end
end
