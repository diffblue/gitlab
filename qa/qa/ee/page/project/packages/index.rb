# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Packages
          module Index
            extend QA::Page::PageConcern

            def wait_for_package_replication(name)
              QA::Runtime::Logger.debug(%[#{self.class.name} - wait_for_package_replication])
              wait_until(max_duration: Runtime::Geo.max_file_replication_time) do
                has_package?(name)
              end
            end
          end
        end
      end
    end
  end
end
