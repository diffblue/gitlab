# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', :requires_admin do
    describe 'Bulk group import' do
      let!(:staging?) { Runtime::Scenario.gitlab_address.include?('staging.gitlab.com') }

      let(:admin_api_client) { Runtime::API::Client.as_admin }
      let(:user) do
        Resource::User.fabricate_via_api! do |usr|
          usr.api_client = admin_api_client
          usr.hard_delete_on_api_removal = true
        end
      end

      let(:api_client) { Runtime::API::Client.new(user: user) }
      let(:personal_access_token) { api_client.personal_access_token }

      let(:sandbox) do
        Resource::Sandbox.fabricate_via_api! do |group|
          group.api_client = admin_api_client
        end
      end

      let(:source_group) do
        Resource::Sandbox.fabricate_via_api! do |group|
          group.api_client = api_client
          group.path = "source-group-for-import-#{SecureRandom.hex(4)}"
        end
      end

      let(:imported_group) do
        Resource::BulkImportGroup.fabricate_via_api! do |group|
          group.api_client = api_client
          group.sandbox = sandbox
          group.source_group_path = source_group.path
        end
      end

      let(:imported_epics) do
        imported_group.epics
      end

      before do
        Runtime::Feature.enable(:bulk_import) unless staging?
        Runtime::Feature.enable(:top_level_group_creation_enabled) if staging?

        sandbox.add_member(user, Resource::Members::AccessLevel::MAINTAINER)

        EE::Resource::Epic.fabricate_via_api! do |epic|
          epic.api_client = api_client
          epic.group = source_group
          epic.title = "Bulk group import test"
          epic.confidential = true
        end
      end

      it 'imports group epics', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1874' do
        expect { imported_group.import_status }.to(
          eventually_eq('finished').within(max_duration: 300, sleep_interval: 2)
        )

        expect(imported_epics).to eq(source_group.epics)
      end

      after do
        user.remove_via_api!
      ensure
        Runtime::Feature.disable(:bulk_import) unless staging?
        Runtime::Feature.disable(:top_level_group_creation_enabled) if staging?
      end
    end
  end
end
