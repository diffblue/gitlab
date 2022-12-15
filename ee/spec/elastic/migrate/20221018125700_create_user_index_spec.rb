# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20221018125700_create_user_index.rb')

RSpec.describe CreateUserIndex, :elastic, :sidekiq_inline, feature_category: :global_search do
  let(:version) { 20221018125700 }
  let(:helper) { Gitlab::Elastic::Helper.new }
  let(:index_name) { User.__elasticsearch__.index_name }

  subject(:migration) { described_class.new(version) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    allow(migration).to receive(:helper).and_return(helper)
    set_elasticsearch_migration_to(version, including: false)

    ensure_elasticsearch_index!
  end

  describe '#migrate' do
    before do
      es_helper.delete_index(index_name: es_helper.target_index_name(target: index_name))
    end

    it 'creates a new index' do
      expect do
        subject.migrate
      end.to change { helper.index_exists?(index_name: index_name) }.from(false).to(true)
    end
  end

  describe '#completed?' do
    it 'delegates to helper.index_exists?' do
      expect(helper).to receive(:index_exists?).with(index_name: index_name).and_return :index_exists
      expect(subject.completed?).to eq(:index_exists)
    end
  end

  describe '#retry_on_failure?' do
    it 'is true' do
      expect(subject.retry_on_failure?).to eq(true)
    end
  end
end
