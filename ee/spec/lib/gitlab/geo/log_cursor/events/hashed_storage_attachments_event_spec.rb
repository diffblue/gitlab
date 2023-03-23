# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo::LogCursor::Events::HashedStorageAttachmentsEvent,
  :clean_gitlab_redis_shared_state,
  feature_category: :geo_replication do
  let(:logger) { Gitlab::Geo::LogCursor::Logger.new(described_class, Logger::INFO) }
  let(:event_log) { create(:geo_event_log, :hashed_storage_attachments_event) }
  let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }
  let(:hashed_storage_attachments_event) { event_log.hashed_storage_attachments_event }
  let(:project) { hashed_storage_attachments_event.project }
  let(:old_attachments_path) { hashed_storage_attachments_event.old_attachments_path }
  let(:new_attachments_path) { hashed_storage_attachments_event.new_attachments_path }

  subject { described_class.new(hashed_storage_attachments_event, Time.now, logger) }

  around do |example|
    Sidekiq::Testing.fake! { example.run }
  end

  describe '#process' do
    it 'does not create a new project registry' do
      expect { subject.process }.not_to change(Geo::ProjectRegistry, :count)
    end

    it 'schedules a Geo::HashedStorageAttachmentsMigrationWorker' do
      expect(::Geo::HashedStorageAttachmentsMigrationWorker).to receive(:perform_async)
        .with(project.id, old_attachments_path, new_attachments_path)

      subject.process
    end

    it_behaves_like 'logs event source info'
  end
end
