# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::RequirementsManagement::RequirementsController, feature_category: :requirements_management do
  let_it_be(:user) { create(:user) }

  shared_examples 'response with 404 status' do
    it 'returns 404' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET #index' do
    subject { get :index, params: { namespace_id: project.namespace, project_id: project } }

    context 'private project' do
      let(:project) { create(:project) }

      context 'with authorized user' do
        before do
          project.add_developer(user)
          sign_in(user)
        end

        context 'when feature is available' do
          before do
            stub_licensed_features(requirements: true)
          end

          it 'renders the index template' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template(:index)
          end
        end

        context 'when feature is not available' do
          before do
            stub_licensed_features(requirements: false)
          end

          it_behaves_like 'response with 404 status'
        end
      end

      context 'with unauthorized user' do
        before do
          sign_in(user)
        end

        context 'when feature is available' do
          before do
            stub_licensed_features(requirements: true)
          end

          it_behaves_like 'response with 404 status'
        end
      end

      context 'with anonymous user' do
        it 'returns 302' do
          subject

          expect(response).to have_gitlab_http_status(:found)
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context 'public project' do
      let(:project) { create(:project, :public) }

      before do
        stub_licensed_features(requirements: true)
      end

      context 'with requirements disabled' do
        before do
          project.project_feature.update!({ requirements_access_level: ::ProjectFeature::DISABLED })
          project.add_developer(user)
          sign_in(user)
        end

        it_behaves_like 'response with 404 status'
      end

      context 'with requirements visible to project members' do
        before do
          project.project_feature.update!({ requirements_access_level: ::ProjectFeature::PRIVATE })
        end

        context 'with authorized user' do
          before do
            project.add_developer(user)
            sign_in(user)
          end

          it 'renders the index template' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template(:index)
          end
        end

        context 'with unauthorized user' do
          before do
            sign_in(user)
          end

          it_behaves_like 'response with 404 status'
        end
      end

      context 'with requirements visible to everyone' do
        before do
          project.project_feature.update!({ requirements_access_level: ::ProjectFeature::ENABLED })
        end

        context 'with anonymous user' do
          it 'renders the index template' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template(:index)
          end
        end
      end
    end
  end

  describe 'GET import_csv' do
    subject { post :import_csv, params: { namespace_id: project.namespace, project_id: project, file: file } }

    let_it_be(:project) { create(:project) }

    let(:upload_service) { double }
    let(:uploader) { double }
    let(:upload) { double }
    let(:file) { 'file' }
    let(:upload_id) { 99 }

    context 'with authorized user' do
      before do
        project.add_developer(user)
        sign_in(user)

        allow(controller).to receive(:file_is_valid?).and_return(true)
      end

      context 'when feature is available' do
        before do
          stub_licensed_features(requirements: true)
        end

        context 'when the upload is processed successfully' do
          before do
            mock_upload
          end

          it 'renders the correct message' do
            expect(RequirementsManagement::ImportRequirementsCsvWorker).to receive(:perform_async)
              .with(user.id, project.id, upload_id)

            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['message']).to eq(
              "Your requirements are being imported. Once finished, you'll receive a confirmation email."
            )
          end
        end

        context 'when the upload returns an error' do
          before do
            mock_upload(false)
          end

          it 'renders the error message' do
            expect(RequirementsManagement::ImportRequirementsCsvWorker).not_to receive(:perform_async)

            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['message']).to eq('File upload error.')
          end
        end
      end

      context 'when feature is not available' do
        before do
          stub_licensed_features(requirements: false)
        end

        it_behaves_like 'response with 404 status'
      end
    end
  end
end
