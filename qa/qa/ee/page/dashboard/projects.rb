# frozen_string_literal: true

module QA
  module EE
    module Page
      module Dashboard
        module Projects
          extend QA::Page::PageConcern

          def self.prepended(base)
            super

            base.class_eval do
              view 'app/views/shared/projects/_list.html.haml' do
                element :projects_list
              end
            end
          end

          def wait_for_project_replication(project_name)
            QA::Runtime::Logger.debug(%Q[#{self.class.name} - wait_for_project_replication])
            wait_until(max_duration: Runtime::Geo.max_db_replication_time) do
              filter_by_name(project_name)

              within_element(:projects_list) do
                has_text?(project_name)
              end
            end
          end

          def projects_list
            find_element(:projects_list)
          end

          def project_created?(project_name)
            fill_element(:project_filter_form_container, project_name)

            wait_until(max_duration: Runtime::Geo.max_db_replication_time) do
              within_element(:projects_list) do
                has_text?(project_name)
              end
            end
          end

          def project_deleted?(project_name)
            fill_element(:project_filter_form_container, project_name)

            wait_until(max_duration: Runtime::Geo.max_db_replication_time) do
              within_element(:projects_list) do
                has_no_text?(project_name)
              end
            end
          end
        end
      end
    end
  end
end
