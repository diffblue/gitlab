# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module New
          extend QA::Page::PageConcern

          def self.prepended(base)
            super

            base.class_eval do
              view 'ee/app/views/projects/_project_templates.html.haml' do
                element 'group-templates-tab'
                element 'group-template-tab-badge-content'
                element 'instance-templates-tab'
                element 'instance-template-tab_badge-content'
              end

              view 'ee/app/views/users/available_group_templates.html.haml' do
                element 'use-template-button'
                element 'template-option-container'
              end

              view 'ee/app/views/users/available_project_templates.html.haml' do
                element 'use-template-button'
                element 'template-option-container'
              end

              view 'app/assets/javascripts/vue_shared/new_namespace/components/welcome.vue' do
                element 'panel-link'
              end
            end
          end

          def go_to_create_from_template_group_tab
            click_element('group-templates-tab')
          end

          def go_to_create_from_template_instance_tab
            click_element(:'instance-templates-tab')
          end

          def group_template_tab_badge_text
            find_element('group-template-tab-badge-content').text
          end

          def instance_template_tab_badge_text
            find_element('instance-template-tab_badge-content').text
          end

          def click_cicd_for_external_repo
            click_element('panel-link', panel_name: 'cicd_for_external_repo')
          end
        end
      end
    end
  end
end
