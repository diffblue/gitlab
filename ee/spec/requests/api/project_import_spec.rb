# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectImport, feature_category: :importers do
  include ExternalAuthorizationServiceHelpers
  include WorkhorseHelpers

  include_context 'workhorse headers'

  let(:user) { create(:user) }
  let(:namespace) { create(:group).tap { |g| g.add_maintainer(user) } }
  let(:file) { File.join('spec', 'features', 'projects', 'import_export', 'test_project_export.tar.gz') }
  let(:file_name) { 'project_export.tar.gz' }

  let(:file_upload) { fixture_file_upload(file) }

  before do
    enable_external_authorization_service_check
    stub_licensed_features(external_authorization_service_api_management: true)
    stub_application_setting(import_sources: ['gitlab_project'])

    namespace.add_owner(user)
  end

  describe 'POST /projects/import' do
    let(:params) do
      {
        path: 'test-import',
        namespace: namespace.id,
        override_params: override_params
      }
    end

    let(:override_params) { { 'external_authorization_classification_label' => 'Hello world' } }

    subject do
      Sidekiq::Testing.inline! do
        upload_archive(file_upload, workhorse_headers, params)
      end
    end

    it 'overrides the classification label' do
      subject

      import_project = Project.find(json_response['id'])
      expect(import_project.external_authorization_classification_label).to eq('Hello world')
    end

    context 'feature is disabled' do
      before do
        stub_licensed_features(external_authorization_service_api_management: false)
      end

      it 'uses the default the classification label and ignores override param' do
        subject

        import_project = Project.find(json_response['id'])
        expect(import_project.external_authorization_classification_label).to eq('default_label')
      end
    end
  end

  def upload_archive(file, headers = {}, params = {})
    workhorse_finalize(
      api("/projects/import", user),
      method: :post,
      file_key: :file,
      params: params.merge(file: file_upload),
      headers: headers,
      send_rewritten_field: true
    )
  end
end
