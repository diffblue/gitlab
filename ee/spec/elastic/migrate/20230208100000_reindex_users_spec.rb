# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20230208100000_reindex_users.rb')

RSpec.describe ReindexUsers, :elastic, :sidekiq_inline, feature_category: :global_search do
  let(:version) { 20230208100000 }
  let(:helper) { Gitlab::Elastic::Helper.new }

  subject(:migration) { described_class.new(version) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    set_elasticsearch_migration_to(version, including: false)
    ensure_elasticsearch_index!
  end

  describe 'integration test' do
    it 'creates a reindexing task, logs useful messages and immediately marks the migration as complete' do
      expect(subject).to receive(:log).with(/Creating Elastic::ReindexingTask with target User/).once
      expect(subject).to receive(:log).with(/Created Elastic::ReindexingTask/).once

      expect { subject.migrate }.to change { Elastic::ReindexingTask.count }.from(0).to(1)

      expect(migration).to be_completed
    end
  end
end
