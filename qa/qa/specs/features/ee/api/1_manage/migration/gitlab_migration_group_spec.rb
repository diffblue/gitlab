# frozen_string_literal: true

# TODO: this needs to be migrated to using 2 gitlab instances
# however currently it's not possible to add license to the second source instance
module QA
  RSpec.describe "Manage", product_group: :import_and_integrate do
    include_context "with gitlab group migration"

    describe "Gitlab migration" do
      context "with EE features" do
        let(:source_iteration) do
          EE::Resource::GroupIteration.fabricate_via_api! do |iteration|
            iteration.api_client = source_admin_api_client
            iteration.group = source_group
            iteration.description = "Import test iteration for group #{source_group.name}"
          end
        end

        let(:source_epics) { source_group.epics }
        let(:imported_epics) { imported_group.epics }

        # Find epic by title
        #
        # @param [Array] epics
        # @param [String] title
        # @return [EE::Resource::Epic]
        def find_epic(epics, title)
          epics.find { |epic| epic.title == title }
        end

        before do
          EE::Resource::License.fabricate! do |resource|
            resource.license = Runtime::Env.ee_license
            resource.api_client = source_admin_api_client
          end

          parent_epic = EE::Resource::Epic.fabricate_via_api! do |resource|
            resource.api_client = source_admin_api_client
            resource.group = source_group
            resource.title = 'Parent epic'
          end

          child_epic = EE::Resource::Epic.fabricate_via_api! do |resource|
            resource.api_client = source_admin_api_client
            resource.group = source_group
            resource.title = 'Child epic'
            resource.confidential = true
            resource.labels = 'label1,label2'
            resource.parent_id = parent_epic.id
          end

          child_epic.award_emoji('thumbsup')
          child_epic.award_emoji('thumbsdown')

          source_iteration
        end

        it(
          'imports group epics and iterations',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347639'
        ) do
          expect_group_import_finished_successfully

          imported_parent_epic = find_epic(imported_epics, 'Parent epic')
          imported_child_epic = find_epic(imported_epics, 'Child epic')
          imported_iteration = imported_group.reload!
            .iterations
            .find { |it| it.description == source_iteration.description }

          aggregate_failures do
            expect(imported_epics).to eq(source_epics)
            expect(imported_child_epic.parent_id).to eq(imported_parent_epic.id)

            expect(imported_iteration).to eq(source_iteration)
            expect(imported_iteration&.iid).to eq(source_iteration.iid)
            expect(imported_iteration&.created_at).to eq(source_iteration.created_at)
            expect(imported_iteration&.updated_at).to eq(source_iteration.updated_at)
          end
        end
      end
    end
  end
end
