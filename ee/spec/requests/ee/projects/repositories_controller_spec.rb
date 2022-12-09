# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::RepositoriesController, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  describe 'GET /archive' do
    subject(:request) { get project_archive_path(project, "master", format: :zip) }

    before do
      allow_next_instance_of(::Users::Abuse::ProjectsDownloadBanCheckService, project, user) do |service|
        allow(service).to receive(:execute).and_return(service_response)
      end

      request
    end

    context "when user is banned from the project's top-level group" do
      let(:service_response) { ServiceResponse.error(message: 'User has been banned') }

      it 'prevents the archive download' do
        expect(response).to have_gitlab_http_status(:forbidden)
        expect(response.body).to match "You are not allowed to download code from this project."
      end
    end

    context "when user is not banned from the project's top-level group" do
      let(:service_response) { ServiceResponse.success }

      it 'proceeds with the archive download' do
        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end
