# frozen_string_literal: true

module QA
  RSpec.describe 'Systems', :orchestrated, :geo, product_group: :geo do
    describe 'GitLab Geo project deletion replication' do
      include Support::API

      deleted_project_name = nil
      deleted_project_id = nil

      before do
        # Need to have at least one project to remain after project deletion,
        # to make sure dashboard shows the project list
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'keep-this-project'
          project.description = 'Geo project to keep'
        end

        project_to_delete = Resource::Project.fabricate_via_api! do |project|
          project.name = 'delete-this-project'
          project.description = 'Geo project to be deleted'
        end

        deleted_project_name = project_to_delete.name
        deleted_project_id = project_to_delete.id
      end

      it 'replicates deletion of a project to secondary node',
         testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348056' do
        QA::Runtime::Logger.debug('Visiting the secondary geo node')

        QA::Flow::Login.while_signed_in(address: :geo_secondary) do
          # Confirm replication of project to secondary node
          Page::Main::Menu.perform(&:go_to_projects)

          Page::Dashboard::Projects.perform do |dashboard|
            expect(dashboard).to be_project_created(deleted_project_name)
          end

          Page::Dashboard::Projects.perform(&:clear_project_filter)

          # Delete project from primary node via API
          delete_response = delete_project_on_primary(deleted_project_id)
          expect(delete_response).to have_content('202 Accepted')

          # Confirm deletion is replicated to secondary node
          Page::Dashboard::Projects.perform do |dashboard|
            expect(dashboard).to be_project_deleted(deleted_project_name)
          end
        end
      end

      def delete_project_on_primary(project_id)
        api_client = Runtime::API::Client.new(:geo_primary)
        delete Runtime::API::Request.new(api_client, "/projects/#{project_id}").url
      end
    end
  end
end
