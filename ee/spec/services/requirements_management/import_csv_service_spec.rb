# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RequirementsManagement::ImportCsvService, feature_category: :requirements_management do
  let_it_be_with_refind(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let(:file) { fixture_file_upload('spec/fixtures/csv_comma.csv') }

  let(:service) do
    uploader = FileUploader.new(project)
    uploader.store!(file)

    described_class.new(user, project, uploader)
  end

  shared_examples 'resource not available' do
    it 'raises an error' do
      expect { service.execute }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  before do
    project.add_reporter(user)
    stub_licensed_features(requirements: true)
  end

  context 'when user can create requirements' do
    include_examples 'issuable import csv service', 'requirement' do
      let(:issuables) { project.requirements }
      let(:email_method) { :import_requirements_csv_email }
    end
  end

  context 'when user cannot create requirements' do
    before do
      project.add_guest(user)
    end

    it_behaves_like 'resource not available'
  end

  context 'when requirements feature is not available' do
    before do
      stub_licensed_features(requirements: false)
    end

    it_behaves_like 'resource not available'
  end
end
