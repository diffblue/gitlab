# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Settings
          module MergeRequest
            extend QA::Page::PageConcern

            def self.prepended(base)
              super

              base.class_eval do
                include Page::Component::SecureReport

                view 'ee/app/views/projects/_merge_pipelines_settings.html.haml' do
                  element :merged_results_pipeline_checkbox
                end

                view 'ee/app/views/projects/_merge_request_settings.html.haml' do
                  element :default_merge_request_template_field
                end

                view 'ee/app/views/projects/_merge_trains_settings.html.haml' do
                  element :merge_trains_checkbox
                end

                view 'ee/app/assets/javascripts/merge_checks/components/merge_checks_app.vue' do
                  element :only_allow_merge_if_all_discussions_are_resolved_checkbox
                end
              end
            end

            def click_pipelines_for_merged_results_checkbox
              check_element(:merged_results_pipeline_checkbox, true)
            end

            def click_merge_trains_checkbox
              check_element(:merge_trains_checkbox, true)
            end

            def enable_merge_train
              click_pipelines_for_merged_results_checkbox
              click_merge_trains_checkbox
              click_save_changes
            end

            def set_default_merge_request_template(template)
              fill_element(:default_merge_request_template_field, template)
              click_save_changes

              wait_for_requests
            end
          end
        end
      end
    end
  end
end

QA::Page::Project::Settings::MergeRequest.prepend_mod_with( # rubocop:disable Cop/InjectEnterpriseEditionModule
  "Page::Project::Settings::MergeRequestApprovals",
  namespace: QA)
