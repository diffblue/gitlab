# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    describe 'Group access',
             :requires_admin, :skip_live_env, :reliable, product_group: :authentication_and_authorization do
      include Runtime::IPAddress

      before(:all) do
        @sandbox_group = Resource::Sandbox.fabricate! do |sandbox_group|
          sandbox_group.path = "gitlab-qa-ip-restricted-sandbox-group-#{SecureRandom.hex(8)}"
        end

        @user = Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1)

        @group = Resource::Group.fabricate_via_api! do |group|
          group.path = "ip-address-restricted-group-#{SecureRandom.hex(8)}"
          group.sandbox = @sandbox_group
        end

        @project = Resource::Project.fabricate_via_api! do |project|
          project.group = @group
          project.name =  'project-in-ip-restricted-group'
          project.initialize_with_readme = true
        end

        @project.add_member(@user)

        @api_client = Runtime::API::Client.new(:gitlab, user: @user)

        enable_plan_on_group(@sandbox_group.path, "Gold") if Specs::Helpers::ContextSelector.dot_com?
      end

      after(:all) do
        @sandbox_group.remove_via_api!

        page.visit Runtime::Scenario.gitlab_address
        Page::Main::Menu.perform(&:sign_out_if_signed_in)
      end

      before do
        page.visit Runtime::Scenario.gitlab_address

        set_ip_address_restriction_to(ip_address)
      end

      context 'when restricted by another ip address' do
        let(:ip_address) { get_next_ip_address(fetch_current_ip_address) }

        context 'with UI' do
          it 'denies access', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347923' do
            Flow::Login.sign_in(as: @user)

            @group.sandbox.visit!(skip_resp_code_check: true)
            expect(page).to have_text('Page Not Found')
            page.go_back

            @group.visit!(skip_resp_code_check: true)
            expect(page).to have_text('Page Not Found')
            page.go_back
          end
        end

        context 'with API' do
          it 'denies access', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347922' do
            request = create_request("/groups/#{@sandbox_group.id}")
            response = get request.url
            expect(response.code).to eq(404)

            request = create_request("/groups/#{@group.id}")
            response = get request.url
            expect(response.code).to eq(404)
          end
        end

        # Note: If you run this test against GDK make sure you've enabled sshd
        # See: https://gitlab.com/gitlab-org/gitlab-qa/blob/master/docs/run_qa_against_gdk.md
        context 'with SSH', :requires_sshd, except: { job: 'review-qa-*' } do
          let(:key) do
            Resource::SSHKey.fabricate_via_api! do |ssh_key|
              ssh_key.api_client = @api_client
              ssh_key.title = "ssh key for allowed ip restricted access #{Time.now.to_f}"
            end
          end

          after do
            key.remove_via_api!
          end

          it 'denies access', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347921' do
            expect { push_a_project_with_ssh_key(key) }.to raise_error(
              QA::Support::Run::CommandError, /fatal: Could not read from remote repository/
            )
          end
        end
      end

      context 'when restricted by user\'s ip address' do
        let(:ip_address) { fetch_current_ip_address }

        context 'with UI' do
          it 'allows access', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347926' do
            Flow::Login.sign_in(as: @user)

            @group.sandbox.visit!
            expect(page).to have_text(@group.sandbox.path)

            @group.visit!
            expect(page).to have_text(@group.path)
          end
        end

        context 'with API' do
          it 'allows access', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347925' do
            request = create_request("/groups/#{@sandbox_group.id}")
            response = get request.url
            expect(response.code).to eq(200)

            request = create_request("/groups/#{@group.id}")
            response = get request.url
            expect(response.code).to eq(200)
          end
        end

        # Note: If you run this test against GDK make sure you've enabled sshd
        # See: https://gitlab.com/gitlab-org/gitlab-qa/blob/master/docs/run_qa_against_gdk.md
        context 'with SSH', :requires_sshd, except: { job: 'review-qa-*' } do
          let(:key) do
            Resource::SSHKey.fabricate_via_api! do |ssh_key|
              ssh_key.api_client = @api_client
              ssh_key.title = "ssh key for allowed ip restricted access #{Time.now.to_f}"
            end
          end

          after do
            key.remove_via_api!
          end

          it 'allows access', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347924' do
            expect { push_a_project_with_ssh_key(key) }.not_to raise_error
          end
        end
      end

      private

      def push_a_project_with_ssh_key(key)
        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = @project
          push.group = @sandbox_group
          push.ssh_key = key
          push.branch_name = "new_branch_#{SecureRandom.hex(8)}"
        end
      end

      def set_ip_address_restriction_to(ip_address)
        Flow::Login.while_signed_in_as_admin do
          @group.sandbox.visit!

          Page::Group::Menu.perform(&:click_group_general_settings_item)

          Page::Group::Settings::General.perform do |settings|
            settings.set_ip_address_restriction(ip_address)
          end
        end
      end

      def get_next_ip_address(current_ip_address)
        current_last_part = current_ip_address.split(".").pop.to_i

        updated_last_part = current_last_part < 255 ? current_last_part + 1 : 1

        current_ip_address.split(".")[0...-1].push(updated_last_part).join(".")
      end

      def enable_plan_on_group(group, plan)
        Flow::Login.while_signed_in_as_admin do
          Page::Main::Menu.perform(&:go_to_admin_area)
          Page::Admin::Menu.perform(&:go_to_groups_overview)

          Page::Admin::Overview::Groups::Index.perform do |index|
            index.search_group(group)
            index.click_group(group)
          end

          Page::Admin::Overview::Groups::Show.perform(&:click_edit_group_link)

          Page::Admin::Overview::Groups::Edit.perform do |edit|
            edit.select_plan(plan)
            edit.click_save_changes_button
          end
        end
      end

      def create_request(api_endpoint)
        Runtime::API::Request.new(@api_client, api_endpoint)
      end
    end
  end
end
