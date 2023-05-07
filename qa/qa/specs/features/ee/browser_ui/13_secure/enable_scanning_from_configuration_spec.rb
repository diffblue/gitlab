# frozen_string_literal: true

module QA
  RSpec.describe 'Secure', :aggregate_failures, product_group: :static_analysis do
    context 'Enable Scanning from UI' do
      let(:test_data_sast_string_fields_array) do
        [
          %w[SECURE_ANALYZERS_PREFIX registry.example.com],
          ['SAST_EXCLUDED_PATHS', 'foo, bar']
        ]
      end

      let(:test_data_int_fields_array) do
        [
          %w[SEARCH_MAX_DEPTH 42],
          %w[SAST_BRAKEMAN_LEVEL 43]
        ]
      end

      let(:test_data_checkbox_exclude_array) do
        %w[kubesec nodejs-scan phpcs-security-audit]
      end

      let(:test_stage_name) do
        'test_all_the_things'
      end

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-with-secure'
          project.description = 'Project with Secure'
        end
      end

      before do
        Resource::Repository::ProjectPush.fabricate! do |project_push|
          project_push.project = project
          project_push.commit_message = 'Create Secure compatible application to serve premade reports'
          project_push.directory = Pathname.new(
            File.join(EE::Runtime::Path.fixtures_path, 'secure_scanning_enable_from_ui_files')
          )
        end

        Flow::Login.sign_in_unless_signed_in
        project.visit!
      end

      describe 'enable dependency scanning from configuration' do
        it(
          'runs dependency scanning job when enabled from configuration',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347621'
        ) do
          Page::Project::Menu.perform(&:go_to_security_configuration)

          Page::Project::Secure::ConfigurationForm.perform do |config_form|
            expect(config_form).to have_dependency_scanning_status('Not enabled')
            expect(config_form).to have_auto_devops_container
            expect(config_form).to have_auto_devops_container_description
            expect(config_form).to have_no_security_configuration_history_link

            config_form.click_dependency_scanning_mr_button
          end

          Page::MergeRequest::New.perform do |new_merge_request|
            expect(new_merge_request).to have_secure_description('Dependency Scanning')
            new_merge_request.create_merge_request
          end

          Page::MergeRequest::Show.perform do |merge_request|
            merge_request.merge_immediately!
          end

          Flow::Pipeline.visit_latest_pipeline

          Page::Project::Pipeline::Show.perform do |pipeline|
            expect(pipeline).to have_job('gemnasium-dependency_scanning')
          end

          Page::Project::Menu.perform(&:go_to_security_configuration)

          Page::Project::Secure::ConfigurationForm.perform do |config_form|
            expect(config_form).to have_dependency_scanning_status('Enabled')
            expect(config_form).to have_no_dependency_scanning_status('Not enabled')
            expect(config_form).to have_security_configuration_history_link
            expect(config_form).to have_no_auto_devops_container

            config_form.click_security_configuration_history_link
          end

          Page::Blame::Show.perform do |file_page|
            expect(file_page).to have_file_content('template: Security/Dependency-Scanning.gitlab-ci.yml')
          end
        end
      end

      describe 'enable sast from configuration' do
        def sast_config_expects(current_page, sast_string_fields, sast_int_fields)
          expect(current_page).to have_file('.gitlab-ci.yml')
          sast_string_fields.each do |field_type, field_value|
            expect(current_page).to have_content("#{field_type}: #{field_value}")
          end
          sast_int_fields.each do |field_type, field_value|
            expect(current_page).to have_content("#{field_type}: '#{field_value}'")
          end
          expect(current_page).to have_content("stage: #{test_stage_name}")
          expect(current_page).to have_content("SAST_EXCLUDED_ANALYZERS: #{test_data_checkbox_exclude_array.join(', ')}")
        end

        it(
          'runs sast job when enabled from configuration',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347685'
        ) do
          Page::Project::Menu.perform(&:go_to_security_configuration)

          Page::Project::Secure::ConfigurationForm.perform do |config_form|
            expect(config_form).to have_sast_status('Not enabled')
            expect(config_form).to have_auto_devops_container
            expect(config_form).to have_auto_devops_container_description
            expect(config_form).to have_no_security_configuration_history_link

            config_form.click_sast_enable_button
            config_form.click_expand_button

            test_data_sast_string_fields_array.each do |test_data_string_array|
              config_form.fill_dynamic_field(test_data_string_array.first, test_data_string_array[1])
            end
            test_data_int_fields_array.each do |test_data_int_array|
              config_form.fill_dynamic_field(test_data_int_array.first, test_data_int_array[1])
            end
            test_data_checkbox_exclude_array.each do |test_data_checkbox|
              config_form.unselect_dynamic_checkbox(test_data_checkbox)
            end
            config_form.fill_dynamic_field('stage', test_stage_name)

            config_form.click_submit_button
          end

          Page::MergeRequest::New.perform do |new_merge_request|
            expect(new_merge_request).to have_secure_description('SAST')

            new_merge_request.click_diffs_tab

            sast_config_expects(new_merge_request, test_data_sast_string_fields_array, test_data_int_fields_array)

            new_merge_request.create_merge_request
          end

          Page::MergeRequest::Show.perform do |merge_request|
            merge_request.merge_immediately!
          end

          Flow::Pipeline.visit_latest_pipeline

          Page::Project::Pipeline::Show.perform do |pipeline|
            expect(pipeline).to have_job('brakeman-sast')
          end

          Page::Project::Menu.perform(&:go_to_security_configuration)

          Page::Project::Secure::ConfigurationForm.perform do |config_form|
            expect(config_form).to have_sast_status('Enabled')
            expect(config_form).to have_no_sast_status('Not enabled')
            expect(config_form).to have_security_configuration_history_link
            expect(config_form).to have_no_auto_devops_container

            config_form.click_security_configuration_history_link
          end

          Page::Blame::Show.perform do |file_page|
            sast_config_expects(file_page, test_data_sast_string_fields_array, test_data_int_fields_array)
          end
        end
      end
    end
  end
end
