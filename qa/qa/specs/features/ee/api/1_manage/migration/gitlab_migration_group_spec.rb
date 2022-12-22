# frozen_string_literal: true

# TODO: this needs to be migrated to using 2 gitlab instances
# however currently it's not possible to add license to the second source instance
module QA
  RSpec.describe 'Manage', :reliable, requires_admin: 'creates a user via API', product_group: :import do
    describe 'Gitlab migration' do
      let(:admin_api_client) { Runtime::API::Client.as_admin }
      let(:api_client) { Runtime::API::Client.new(user: user) }
      # validate different epic author is migrated correctly
      let(:author_api_client) { Runtime::API::Client.new(user: author) }

      let(:user) do
        Resource::User.fabricate_via_api! do |usr|
          usr.api_client = admin_api_client
          usr.hard_delete_on_api_removal = true
        end
      end

      let(:author) do
        Resource::User.fabricate_via_api! do |usr|
          usr.api_client = admin_api_client
          usr.hard_delete_on_api_removal = true
        end
      end

      let(:sandbox) do
        Resource::Sandbox.fabricate_via_api! do |group|
          group.api_client = admin_api_client
        end
      end

      let(:destination_group) do
        Resource::Group.fabricate_via_api! do |group|
          group.api_client = api_client
          group.sandbox = sandbox
          group.path = "destination-group-for-import-#{SecureRandom.hex(4)}"
        end
      end

      let(:source_group) do
        Resource::Group.fabricate_via_api! do |group|
          group.api_client = api_client
          group.sandbox = sandbox
          group.path = "source-group-for-import-#{SecureRandom.hex(4)}"
          group.avatar = File.new('qa/fixtures/designs/tanuki.jpg', 'r')
        end
      end

      let(:imported_group) do
        Resource::BulkImportGroup.fabricate_via_api! do |group|
          group.api_client = api_client
          group.sandbox = destination_group
          group.source_group = source_group
        end
      end

      let(:source_epics) { source_group.epics }
      let(:imported_epics) { imported_group.epics }

      let(:source_iteration) do
        EE::Resource::GroupIteration.fabricate_via_api! do |iteration|
          iteration.api_client = api_client
          iteration.group = source_group
          iteration.description = "Import test iteration for group #{source_group.name}"
        end
      end

      let(:import_failures) do
        imported_group.import_details.sum([]) { |details| details[:failures] }
      end

      # Find epic by title
      #
      # @param [Array] epics
      # @param [String] title
      # @return [EE::Resource::Epic]
      def find_epic(epics, title)
        epics.find { |epic| epic.title == title }
      end

      before do
        unless Runtime::ApplicationSettings.get_application_settings[:bulk_import_enabled]
          Runtime::ApplicationSettings.set_application_settings(bulk_import_enabled: true)
        end

        sandbox.add_member(user, Resource::Members::AccessLevel::MAINTAINER)
        source_group.add_member(author, Resource::Members::AccessLevel::MAINTAINER)
        author.set_public_email

        parent_epic = EE::Resource::Epic.fabricate_via_api! do |epic|
          epic.api_client = author_api_client
          epic.group = source_group
          epic.title = 'Parent epic'
        end
        child_epic = EE::Resource::Epic.fabricate_via_api! do |child_epic|
          child_epic.api_client = api_client
          child_epic.group = source_group
          child_epic.title = 'Child epic'
          child_epic.confidential = true
          child_epic.labels = 'label1,label2'
          child_epic.parent_id = parent_epic.id
        end

        child_epic.award_emoji('thumbsup')
        child_epic.award_emoji('thumbsdown')

        source_iteration

        imported_group # trigger import
      end

      after do |example|
        # Checking for failures in the test currently makes test very flaky due to catching unrelated failures
        # Log failures for easier debugging
        Runtime::Logger.warn("Import failures: #{import_failures}") if example.exception && !import_failures.empty?
      ensure
        user.remove_via_api!
        author.remove_via_api!
      end

      it(
        'imports group epics and iterations',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347639'
      ) do
        expect { imported_group.import_status }.to(
          eventually_eq('finished').within(max_duration: 300, sleep_interval: 2)
        )

        source_parent_epic = find_epic(source_epics, 'Parent epic')
        imported_parent_epic = find_epic(imported_epics, 'Parent epic')
        imported_child_epic = find_epic(imported_epics, 'Child epic')
        imported_iteration = imported_group.reload!
          .iterations
          .find { |it| it.description == source_iteration.description }

        aggregate_failures do
          expect(imported_epics).to eq(source_epics)
          expect(imported_child_epic.parent_id).to eq(imported_parent_epic.id)
          expect(imported_parent_epic.author).to eq(source_parent_epic.author)

          expect(imported_iteration).to eq(source_iteration)
          expect(imported_iteration&.iid).to eq(source_iteration.iid)
          expect(imported_iteration&.created_at).to eq(source_iteration.created_at)
          expect(imported_iteration&.updated_at).to eq(source_iteration.updated_at)
        end
      end
    end
  end
end
