# frozen_string_literal: true

require 'pathname'

module QA
  RSpec.describe 'Secure', :runner do
    describe 'Enable SAST from UI' do
      let(:merge_request_description) do
        <<~DESCRIPTION.tr("\n", ' ').strip
          Configure SAST in `.gitlab-ci.yml` using the GitLab managed template. You can
          [add variable overrides](https://docs.gitlab.com/ee/user/application_security/sast/#customizing-the-sast-settings)
          to customize SAST settings.
        DESCRIPTION
      end

      let(:test_data_string_fields_array) do
        [
          %w(SECURE_ANALYZERS_PREFIX registry.example.com),
          %w(SAST_EXCLUDED_PATHS foo,\ bar),
          %w(SAST_BANDIT_EXCLUDED_PATHS exclude_path_a,\ exclude_path_b)
        ]
      end

      let(:test_data_int_fields_array) do
        [
          %w(SEARCH_MAX_DEPTH 42),
          %w(SAST_BRAKEMAN_LEVEL 43),
          %w(SAST_GOSEC_LEVEL 7)
        ]
      end

      let(:test_data_checkbox_exclude_array) do
        %w(eslint kubesec nodejs-scan phpcs-security-audit)
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

      let!(:runner) do
        Resource::Runner.fabricate! do |runner|
          runner.project = project
          runner.name = "runner-for-#{project.name}"
          runner.tags = ['secure_sast']
        end
      end

      after do
        runner&.remove_via_api!
      end

      before do
        # Push fixture to generate Secure reports
        Resource::Repository::ProjectPush.fabricate! do |project_push|
          project_push.project = project
          project_push.directory = Pathname
                                       .new(__dir__)
                                       .join('../../../../../ee/fixtures/secure_sast_enable_from_ui_files')
          project_push.commit_message = 'Create Secure compatible application to serve premade reports'
        end

        Flow::Login.sign_in_unless_signed_in
        project.visit!
      end

      it 'runs sast job when enabled from configuration', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1667' do
        Flow::Pipeline.visit_latest_pipeline

        # Baseline that we do not initially have a sast job
        Page::Project::Pipeline::Show.perform do |pipeline|
          expect(pipeline).to have_no_job('brakeman-sast')
        end
        Page::Project::Menu.perform(&:click_on_security_configuration_link)

        Page::Project::Secure::ConfigurationForm.perform do |config_form|
          expect(config_form).to have_sast_status('Not enabled')

          config_form.click_sast_enable_button
          config_form.click_expand_button

          test_data_string_fields_array.each do |test_data_string_array|
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
          expect(new_merge_request).to have_description(merge_request_description)

          new_merge_request.click_diffs_tab

          aggregate_failures "test Merge Request contents" do
            expect(new_merge_request).to have_file('.gitlab-ci.yml')
            test_data_string_fields_array.each do |test_data_string_array|
              expect(new_merge_request).to have_content("#{test_data_string_array.first}: #{test_data_string_array[1]}")
            end
            test_data_int_fields_array.each do |test_data_int_array|
              expect(new_merge_request).to have_content("#{test_data_int_array.first}: '#{test_data_int_array[1]}'")
            end
            expect(new_merge_request).to have_content("stages: - test - #{test_stage_name}")
            expect(new_merge_request).to have_content("SAST_EXCLUDED_ANALYZERS: #{test_data_checkbox_exclude_array.join(', ')}")
          end

          new_merge_request.create_merge_request
        end

        Page::MergeRequest::Show.perform do |merge_request|
          merge_request.try_to_merge!
        end

        Flow::Pipeline.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |pipeline|
          expect(pipeline).to have_job('brakeman-sast')
        end

        Page::Project::Menu.perform(&:click_on_security_configuration_link)

        Page::Project::Secure::ConfigurationForm.perform do |config_form|
          aggregate_failures "test SAST status is Enabled" do
            expect(config_form).to have_sast_status('Enabled')
            expect(config_form).not_to have_sast_status('Not enabled')
          end
        end
      end
    end
  end
end
