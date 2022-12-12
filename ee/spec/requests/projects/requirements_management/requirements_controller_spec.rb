# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::RequirementsManagement::RequirementsController, feature_category: :requirements_management do
  include WorkhorseHelpers

  include_context 'workhorse headers'

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  shared_examples 'response with 404 status' do
    it 'returns 404' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'POST #import_csv' do
    let(:file) { fixture_file_upload('spec/fixtures/csv_comma.csv') }
    let(:params) { { namespace_id: project.namespace.id, path: 'test' } }

    subject { upload_file(file, workhorse_headers, params) }

    context 'unauthorized' do
      context 'when user is not signed in' do
        it_behaves_like 'response with 404 status'
      end

      context 'with project member with a guest role' do
        before do
          login_as(user)
          project.add_guest(user)
        end

        it_behaves_like 'response with 404 status'
      end
    end

    context 'authorized' do
      before do
        login_as(user)
        project.add_reporter(user)
      end

      context 'when requirements feature is available and member is a reporter' do
        before do
          stub_licensed_features(requirements: true)
        end

        shared_examples 'response with success status' do
          it 'returns 200 status and success message' do
            subject

            expect(response).to have_gitlab_http_status(:success)
            expect(json_response).to eq('message' => "Your requirements are being imported. Once finished, you'll receive a confirmation email.")
          end
        end

        it_behaves_like 'response with success status'

        context 'when file extension is in upper case' do
          let(:file) { fixture_file_upload('spec/fixtures/csv_uppercase.CSV') }

          it_behaves_like 'response with success status'
        end

        it 'shows error when upload fails' do
          expect_next_instance_of(UploadService) do |upload_service|
            expect(upload_service).to receive(:execute).and_return(nil)
          end

          subject

          expect(json_response).to eq('message' => 'File upload error.')
        end

        context 'when file extension is not csv' do
          let(:file) { fixture_file_upload('spec/fixtures/sample_doc.md') }

          it 'returns error message' do
            subject

            expect(response).to have_gitlab_http_status(:success)
            expect(json_response).to eq('message' => "The uploaded file was invalid. Supported file extensions are .csv.")
          end
        end
      end

      context 'when requirements feature is not available' do
        before do
          stub_licensed_features(requirements: false)
        end

        it_behaves_like 'response with 404 status'
      end
    end

    def upload_file(file, headers = {}, params = {})
      workhorse_finalize(
        import_csv_project_requirements_management_requirements_path(project),
        method: :post,
        file_key: :file,
        params: params.merge(file: file),
        headers: headers,
        send_rewritten_field: true
      )
    end
  end

  describe 'POST #authorize' do
    subject do
      post import_csv_authorize_project_requirements_management_requirements_path(project),
        headers: workhorse_headers
    end

    before do
      login_as(user)
      stub_licensed_features(requirements: true)
    end

    context 'with authorized user' do
      before do
        project.add_reporter(user)
      end

      context 'when requirements feature is enabled' do
        it_behaves_like 'handle uploads authorize request' do
          let(:uploader_class) { FileUploader }
          let(:maximum_size) { Gitlab::CurrentSettings.max_attachment_size.megabytes }
        end
      end

      context 'when requirements feature is disabled' do
        before do
          stub_licensed_features(requirements: false)
        end

        it_behaves_like 'response with 404 status'
      end
    end

    context 'with unauthorized user' do
      it_behaves_like 'response with 404 status'
    end
  end
end
