# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:uploads:migrate and migrate_to_local rake tasks', :silence_stdout do
  let(:model_class) { nil }
  let(:uploader_class) { nil }
  let(:mounted_as) { nil }
  let(:batch_size) { 3 }

  before do
    stub_env('MIGRATION_BATCH_SIZE', batch_size.to_s)
    stub_uploads_object_storage(uploader_class)
    Rake.application.rake_require 'tasks/gitlab/uploads/migrate'

    allow(ObjectStorage::MigrateUploadsWorker).to receive(:perform_async)
  end

  context 'for MetricImageUploader' do
    let(:uploader_class) { MetricImageUploader }
    let(:model_class) {  IssuableMetricImage }
    let(:mounted_as) { :file }

    before do
      issue = create(:issue)
      create_list(:issuable_metric_image, 10, :local, issue: issue)
    end

    it_behaves_like 'enqueue upload migration jobs in batch', batch: 4
  end
end
