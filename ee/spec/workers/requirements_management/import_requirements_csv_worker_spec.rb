# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RequirementsManagement::ImportRequirementsCsvWorker, feature_category: :requirements_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:upload) { create(:upload, :with_file) }

  before_all do
    project.add_reporter(user)
  end

  before do
    stub_licensed_features(requirements: true)
  end

  subject { described_class.new.perform(user.id, project.id, upload.id) }

  describe '#perform' do
    it 'calls #execute on Requirements::ImportCsvService and destroys upload' do
      expect_next_instance_of(RequirementsManagement::ImportCsvService) do |instance|
        expect(instance).to receive(:execute).and_return({ success: 5, error_lines: [], parse_error: false })
      end

      subject

      expect { upload.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [user.id, project.id, upload.id] }
    end
  end
end
