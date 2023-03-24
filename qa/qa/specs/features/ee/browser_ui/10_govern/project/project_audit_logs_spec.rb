# frozen_string_literal: true

module QA
  RSpec.describe(
    'Govern',
    product_group: :compliance
  ) do
    shared_examples 'audit event' do |expected_events|
      it 'logs audit events for UI operations' do
        QA::Support::Retrier.retry_on_exception do
          Page::Project::Menu.perform(&:go_to_audit_events)
        end
        expected_events.each do |expected_event|
          expect(page).to have_text(expected_event)
        end
      end
    end

    describe 'Project', :reliable do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'awesome-project'
          project.initialize_with_readme = true
        end
      end

      let(:user) do
        Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1)
      end

      before do
        sign_in
      end

      context "for add project", testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347904' do
        before do
          Resource::Project.fabricate_via_browser_ui! do |project|
            project.name = 'audit-add-project-via-ui'
            project.initialize_with_readme = true
            project.description = nil
          end.visit!
        end

        it_behaves_like 'audit event', ["Added project"]
      end

      context "for add user access as guest",
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347906' do
        before do
          project.visit!

          Page::Project::Menu.perform(&:click_members)
          Page::Project::Members.perform do |members|
            members.add_member(user.username, 'Guest')
          end
        end

        it_behaves_like 'audit event', ["Added user access as Guest"]
      end

      context "for add deploy key", testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347907' do
        before do
          key = Runtime::Key::RSA.new
          deploy_key_title = 'deploy key title'
          deploy_key_value = key.public_key

          Resource::DeployKey.fabricate_via_browser_ui! do |resource|
            resource.project = project
            resource.title = deploy_key_title
            resource.key = deploy_key_value
          end
        end

        it_behaves_like 'audit event', ["Added deploy key"]
      end

      context "for change visibility", testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347905' do
        before do
          project.visit!

          Page::Project::Menu.perform(&:go_to_general_settings)
          Page::Project::Settings::Main.perform do |settings|
            # Change visibility from public to internal
            settings.expand_visibility_project_features_permissions do |page|
              page.set_project_visibility "Private"
            end
          end
        end

        it_behaves_like 'audit event', ["Changed visibility level from Public to Private"]
      end

      context "for export file download", :skip_live_env,
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347939' do
        before do
          QA::Support::Retrier.retry_until do
            project = Resource::Project.fabricate_via_api! do |project|
              project.name = 'project_for_export'
              project.initialize_with_readme = true
            end

            project.visit!

            Page::Project::Menu.perform(&:go_to_general_settings)
            Page::Project::Settings::Main.perform do |settings|
              settings.expand_advanced_settings(&:click_export_project_link)
              expect(page).to have_text("Project export started") # rubocop:disable RSpec/ExpectInHook

              Page::Project::Menu.perform(&:go_to_general_settings)
              settings.expand_advanced_settings do |advanced_settings|
                advanced_settings.scroll_to_element(:export_project_content)
                advanced_settings.has_download_export_link?
              end
            end
          end

          Page::Project::Settings::Main.perform do |settings|
            settings.expand_advanced_settings(&:click_download_export_link)
          end
        end

        it_behaves_like 'audit event', ["Export file download started"]
      end

      context "for project archive and unarchive",
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347903' do
        before do
          project.visit!

          # Archive project
          Page::Project::Menu.perform(&:go_to_general_settings)
          Page::Project::Settings::Main.perform(&:expand_advanced_settings)
          Page::Project::Settings::Advanced.perform(&:archive_project)
          Support::Waiter.wait_until { page.has_text?('Archived project!') }

          # Unarchive project
          Page::Project::Menu.perform(&:go_to_general_settings)
          Page::Project::Settings::Main.perform(&:expand_advanced_settings)
          Page::Project::Settings::Advanced.perform(&:unarchive_project)
        end

        it_behaves_like 'audit event', ["Project archived", "Project unarchived"]
      end

      def sign_in
        Flow::Login.sign_in unless Page::Main::Menu.perform { |p| p.has_personal_area?(wait: 0) }
      end
    end
  end
end
