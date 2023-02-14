# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20230208090000_delete_removed_fields_from_users.rb')

RSpec.describe DeleteRemovedFieldsFromUsers, :elastic, :sidekiq_inline, feature_category: :global_search do
  let(:version) { 20230208090000 }
  let(:helper) { Gitlab::Elastic::Helper.default }

  subject(:migration) { described_class.new(version) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    set_elasticsearch_migration_to(version, including: false)
    recreate_user_index_without_mappings!
    ensure_elasticsearch_index!
    allow(migration).to receive(:log)
  end

  describe 'migration_options' do
    it 'has migration options set', :aggregate_failures do
      expect(migration.batched?).to be_truthy
      expect(migration.throttle_delay).to eq(1.minute)
    end
  end

  describe '#migrate' do
    let!(:user_1) { create(:user) }
    let!(:user_2) { create(:user) }
    let!(:user_3) { create(:user) }

    before do
      ensure_elasticsearch_index!
    end

    context 'when migration is completed' do
      before do
        remove_data_for_users([user_1, user_2, user_3])
      end

      it 'does not update documents', :aggregate_failures do
        expect(migration.completed?).to be_truthy
        expect(migration).not_to receive(:update_by_query!)

        migration.migrate
      end
    end

    context 'when migration is not complete' do
      before do
        add_data_for_users([user_1, user_2, user_3])
      end

      it 'updates documents' do
        expect(migration).to receive(:update_by_query!).once.and_call_original
        expect(migration).to receive(:log).with(/3 updates were made/).once

        migration.migrate
      end

      it 'only updates documents that contain data for fields', :aggregate_failures do
        remove_data_for_users([user_1, user_2])

        expect(migration).to receive(:update_by_query!).once.and_call_original
        expect(migration).to receive(:log).with(/1 updates were made/).once

        migration.migrate
      end

      it 'processes in batches until completed' do
        stub_const("#{described_class}::BATCH_SIZE", 2)

        expect(migration).to receive(:update_by_query!).twice.and_call_original

        expect(migration.completed?).to be_falsey

        expect(migration).to receive(:log).with(/2 updates were made/).once

        ensure_elasticsearch_index!
        migration.migrate

        expect(migration.completed?).to be_falsey

        expect(migration).to receive(:log).with(/1 updates were made/).once

        ensure_elasticsearch_index!
        migration.migrate

        expect(migration.completed?).to be_truthy
      end
    end
  end

  describe '#completed?' do
    let!(:user) { create(:user) }

    before do
      ensure_elasticsearch_index!
    end

    subject { migration.completed? }

    context 'when no documents have the data' do
      before do
        remove_data_for_users([user])
      end

      it { is_expected.to be_truthy }
    end

    context 'when documents have the data' do
      before do
        add_data_for_users([user])
      end

      it { is_expected.to be_falsey }
    end
  end

  private

  def add_data_for_users(users)
    script =  {
      source: "ctx._source['two_factor_enabled'] = params.two_factor_enabled;\
      ctx._source['has_projects'] = params.has_projects;",
      lang: "painless",
      params: {
        two_factor_enabled: true,
        has_projects: false
      }
    }

    update_by_script(users, script)
  end

  def remove_data_for_users(users)
    script =  {
      source: "ctx._source.remove('two_factor_enabled'); ctx._source.remove('has_projects');"
    }

    update_by_script(users, script)
  end

  def update_by_script(users, script)
    user_ids = users.pluck(:id)

    client = User.__elasticsearch__.client
    client.update_by_query({
      index: User.__elasticsearch__.index_name,
      wait_for_completion: true,
      refresh: true,
      body: {
        script: script,
        query: {
          terms: {
            id: user_ids
          }
        }
      }
    })
  end

  def recreate_user_index_without_mappings!
    indices = helper.client.indices.get_alias(name: 'gitlab-test-users')
    indices.each_key { |index| helper.delete_index(index_name: index) }

    allow_next_instance_of(Elastic::Latest::ApplicationClassProxy) do |proxy|
      allow(proxy).to receive(:mappings).and_return(Elasticsearch::Model::Indexing::Mappings.new)
    end

    helper.create_standalone_indices(with_alias: true, target_classes: [User])
  end
end
