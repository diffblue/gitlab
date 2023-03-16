# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ElasticRemoveExpiredNamespaceSubscriptionsFromIndexCronWorker, :saas, feature_category: :global_search do
  subject { described_class.new }

  let(:not_expired_subscription1) { create(:gitlab_subscription, :bronze, end_date: Date.today + 2) }
  let(:not_expired_subscription2) { create(:gitlab_subscription, :bronze, end_date: Date.today + 100) }
  let(:recently_expired_subscription) { create(:gitlab_subscription, :bronze, end_date: Date.today - 4) }
  let(:expired_subscription1) { create(:gitlab_subscription, :bronze, end_date: Date.today - 31) }
  let(:expired_subscription2) { create(:gitlab_subscription, :bronze, end_date: Date.today - 35) }

  before do
    allow(::Gitlab).to receive(:com?).and_return(true)
    ElasticsearchIndexedNamespace.safe_find_or_create_by!(namespace_id: not_expired_subscription1.namespace_id)
    ElasticsearchIndexedNamespace.safe_find_or_create_by!(namespace_id: not_expired_subscription2.namespace_id)
    ElasticsearchIndexedNamespace.safe_find_or_create_by!(namespace_id: recently_expired_subscription.namespace_id)
    ElasticsearchIndexedNamespace.safe_find_or_create_by!(namespace_id: expired_subscription1.namespace_id)
    ElasticsearchIndexedNamespace.safe_find_or_create_by!(namespace_id: expired_subscription2.namespace_id)
  end

  it_behaves_like 'an idempotent worker' do
    it 'finds the subscriptions that expired over a week ago that are in the index and deletes them' do
      expect(ElasticNamespaceIndexerWorker).to receive(:perform_async).with(expired_subscription1.namespace_id, :delete)
      expect(ElasticNamespaceIndexerWorker).to receive(:perform_async).with(expired_subscription2.namespace_id, :delete)

      subject

      expect(ElasticsearchIndexedNamespace.all.pluck(:namespace_id)).to contain_exactly(
        not_expired_subscription1.namespace_id,
        not_expired_subscription2.namespace_id,
        recently_expired_subscription.namespace_id
      )
    end
  end

  context 'when not com?' do
    before do
      allow(::Gitlab).to receive(:com?).and_return(false)
    end

    it 'does nothing' do
      expect { subject.perform }.not_to change { ElasticsearchIndexedNamespace.count }
    end
  end

  context 'when the exclusive lease is already locked' do
    before do
      # Don't yield
      expect(subject).to receive(:in_lock).with(described_class.name.underscore, ttl: 1.hour, retries: 0)
    end

    it 'does nothing' do
      expect { subject.perform }.not_to change { ElasticsearchIndexedNamespace.count }
    end
  end
end
