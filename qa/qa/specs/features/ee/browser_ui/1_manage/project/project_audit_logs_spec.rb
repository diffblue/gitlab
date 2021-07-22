# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    shared_examples 'audit event' do |expected_events|
      it 'logs audit events for UI operations' do
        Page::Project::Menu.perform(&:go_to_audit_events_settings)
        expected_events.each do |expected_event|
          expect(page).to have_text(expected_event)
        end
      end
    end

    describe 'Project', :requires_admin do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'awesome-project'
          project.initialize_with_readme = true
        end
      end

      before do
        sign_in
      end

      let(:user) { Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1) }

      context "Add project",
              testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/727' do
        before do
          Resource::Project.fabricate_via_browser_ui! do |project|
            project.name = 'audit-add-project-via-ui'
            project.initialize_with_readme = true
          end.visit!
        end
        it_behaves_like 'audit event', ["Added project"]
      end

      # TODO: Remove :requires_admin meta when the `Runtime::Feature.enable` method call is removed
      context "Add user access as guest", :requires_admin, testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/729' do
        before do
          Runtime::Feature.enable(:invite_members_group_modal)
          project.visit!

          Page::Project::Menu.perform(&:click_members)
          Page::Project::Members.perform do |members|
            members.add_member(user.username, 'Guest')
          end
        end

        it_behaves_like 'audit event', ["Added user access as Guest"]
      end

      context "Add deploy key", testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/730' do
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

      context "Change visibility", testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/728' do
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

        it_behaves_like 'audit event', ["Changed visibility from Public to Private"]
      end

      context "Export file download", :skip_live_env, testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1127' do
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
              expect(page).to have_text("Project export started")

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

      context "Project archive and unarchive", testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/726' do
        before do
          project.visit!

          # Project archive
          Page::Project::Menu.perform(&:go_to_general_settings)
          Page::Project::Settings::Main.perform do |settings|
            settings.expand_advanced_settings(&:archive_project)
          end

          # Project unarchived
          Page::Project::Menu.perform(&:go_to_general_settings)
          Page::Project::Settings::Main.perform do |settings|
            settings.expand_advanced_settings(&:unarchive_project)
          end
        end

        it_behaves_like 'audit event', ["Project archived", "Project unarchived"]
      end

      def sign_in
        unless Page::Main::Menu.perform { |p| p.has_personal_area?(wait: 0) }
          Flow::Login.sign_in
        end
      end
    end
  end
end
