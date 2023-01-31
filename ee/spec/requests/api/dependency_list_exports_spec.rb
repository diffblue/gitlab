# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::DependencyListExports, feature_category: :dependency_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  describe 'POST /projects/:id/dependency_list_exports' do
    let(:request_path) { "/projects/#{project.id}/dependency_list_exports" }

    subject(:create_dependency_list_export) { post api(request_path, user) }

    context 'with user without permission' do
      before do
        stub_licensed_features(dependency_scanning: true)
        project.add_guest(user)
      end

      it 'returns 403' do
        expect(::Dependencies::CreateExportService).not_to receive(:new)

        create_dependency_list_export

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with user with enough permission' do
      before do
        project.add_developer(user)
      end

      context 'with license feature disabled' do
        before do
          stub_licensed_features(dependency_scanning: false)
        end

        it 'returns 403' do
          expect(::Dependencies::CreateExportService).not_to receive(:new)

          create_dependency_list_export

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'with license feature enabled' do
        before do
          stub_licensed_features(dependency_scanning: true)
        end

        it 'creates and returns a dependency_list_export' do
          expect(::Dependencies::CreateExportService).to receive(:new).with(project, user).and_call_original

          create_dependency_list_export

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response).to have_key('id')
          expect(json_response).to have_key('has_finished')
          expect(json_response).to have_key('self')
          expect(json_response).to have_key('download')
        end
      end
    end
  end

  describe 'GET /projects/:id/dependency_list_exports/:export_id' do
    let(:dependency_list_export) { create(:dependency_list_export, :finished) }
    let(:request_path) { "/projects/#{project.id}/dependency_list_exports/#{dependency_list_export.id}" }

    subject(:fetch_dependency_list_export) { get api(request_path, user) }

    context 'with user without permission' do
      before do
        stub_licensed_features(dependency_scanning: true)
        project.add_guest(user)
      end

      it 'returns 403' do
        expect(::Dependencies::FetchExportService).not_to receive(:new)

        fetch_dependency_list_export

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with user with enough permission' do
      before do
        project.add_developer(user)
      end

      context 'with license feature disabled' do
        before do
          stub_licensed_features(dependency_scanning: false)
        end

        it 'returns 403' do
          expect(::Dependencies::FetchExportService).not_to receive(:new)

          fetch_dependency_list_export

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'with license feature enabled' do
        before do
          stub_licensed_features(dependency_scanning: true)
        end

        it 'fetches and returns a dependency_list_export' do
          expect(::Dependencies::FetchExportService).to receive(:new)
          .with(dependency_list_export.id)
          .and_call_original

          fetch_dependency_list_export

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to have_key('id')
          expect(json_response).to have_key('has_finished')
          expect(json_response).to have_key('self')
          expect(json_response).to have_key('download')
        end

        context 'with dependency list export not finished' do
          let(:dependency_list_export) { create(:dependency_list_export) }

          it 'sets polling and returns accepted' do
            expect(::Dependencies::FetchExportService).to receive(:new)
            .with(dependency_list_export.id)
            .and_call_original
            expect(::Gitlab::PollingInterval).to receive(:set_api_header).and_call_original

            fetch_dependency_list_export

            expect(response).to have_gitlab_http_status(:accepted)
          end
        end
      end
    end
  end

  describe 'GET /projects/:id/dependency_list_exports/:export_id/download' do
    let(:dependency_list_export) { create(:dependency_list_export, :finished) }
    let(:request_path) { "/projects/#{project.id}/dependency_list_exports/#{dependency_list_export.id}/download" }

    subject(:download_dependency_list_export) { get api(request_path, user) }

    context 'with user without permission' do
      before do
        stub_licensed_features(dependency_scanning: true)
        project.add_guest(user)
      end

      it 'returns 403' do
        expect(::Dependencies::FetchExportService).not_to receive(:new)

        download_dependency_list_export

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with user with enough permission' do
      before do
        project.add_developer(user)
      end

      context 'with license feature disabled' do
        before do
          stub_licensed_features(dependency_scanning: false)
        end

        it 'returns 403' do
          expect(::Dependencies::FetchExportService).not_to receive(:new)

          download_dependency_list_export

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'with license feature enabled' do
        before do
          stub_licensed_features(dependency_scanning: true)
        end

        it 'returns file content' do
          expect(::Dependencies::FetchExportService).to receive(:new)
          .with(dependency_list_export.id)
          .and_call_original

          download_dependency_list_export

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to have_key('report')
          expect(json_response).to have_key('dependencies')
        end

        context 'with dependency list export not finished' do
          let(:dependency_list_export) { create(:dependency_list_export) }

          it 'returns 404' do
            expect(::Dependencies::FetchExportService).to receive(:new)
            .with(dependency_list_export.id)
            .and_call_original

            download_dependency_list_export

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end
  end
end
