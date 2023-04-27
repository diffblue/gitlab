# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::IndexCurationWorker, feature_category: :global_search do
  include StubFeatureFlags
  subject { described_class.new }

  let(:curator) { ::Gitlab::Search::IndexCurator }
  let(:settings) { subject.curator_settings }
  let(:logger) { ::Gitlab::Elasticsearch::Logger.build }

  describe '#curator_settings' do
    let(:standalone_index_types) { %w[commits issues merge_requests notes users wikis] }
    let(:curation_include_patterns) { [main_index_pattern] + standalone_index_types.map { |x| /#{x}/ } }
    let(:main_index_target_name) { "gitlab-test" }
    let(:main_index_name) { "gitlab-test-20220923-1517" }
    let(:main_index_pattern) { /gitlab-test-20220923-/ }
    let(:stubbed_helper) { instance_double(::Gitlab::Elastic::Helper) }
    let(:curator_settings) { described_class.new.curator_settings }
    let(:application_settings) { Gitlab::CurrentSettings }

    before do
      allow(::Gitlab::Elastic::Helper).to receive(:default).and_return(stubbed_helper)
      allow(stubbed_helper).to receive(:target_name).and_return(main_index_target_name)
      allow(stubbed_helper).to receive(:target_index_name).with(target: main_index_target_name)
        .and_return main_index_name
    end

    it 'includes a pattern for all index types with enabled feature flags' do
      expect(settings[:include_patterns]).to contain_exactly(*curation_include_patterns)
    end

    it 'does not include patterns for disabled index types' do
      standalone_index_types.each do |index_type|
        curation_include_patterns.delete(/#{index_type}/)
        stub_feature_flags("search_index_curation_#{index_type}" => false)
        expect(described_class.new.curator_settings[:include_patterns]).to contain_exactly(*curation_include_patterns)
      end

      stub_feature_flags(search_index_curation_main_index: false)
      curation_include_patterns.delete(main_index_pattern)
      expect(described_class.new.curator_settings[:include_patterns]).to contain_exactly(*curation_include_patterns)
    end

    it 'has correct value for max_shard_size_gb' do
      expect(curator_settings[:max_shard_size_gb]).to eq(application_settings.search_max_shard_size_gb)
    end

    it 'has correct value for max_docs_denominator' do
      expect(curator_settings[:max_docs_denominator]).to eq(application_settings.search_max_docs_denominator)
    end

    it 'has correct value for min_docs_before_rollover' do
      expect(curator_settings[:min_docs_before_rollover]).to eq(application_settings.search_min_docs_before_rollover)
    end
  end

  describe '#perform' do
    before do
      allow(subject).to receive(:logger).and_return(logger)
    end

    it 'calls on the curator' do
      expect(curator).to receive(:curate).with(settings)
      expect(subject.perform).not_to be_falsey
    end

    it 'logs rolled over indices' do
      rollover_info = [{ from: 'foo', to: 'bar' }]
      allow(curator).to receive(:curate).and_return(rollover_info)
      expect(logger).to receive(:info).with(/#{rollover_info.first[:from]} => #{rollover_info.first[:to]}/)
      subject.perform
    end

    it 'logs errors when something blows up' do
      allow(curator).to receive(:curate).and_raise "kaboom"
      expect(logger).to receive(:error).with(/kaboom/)
      subject.perform
    end

    it 'does not log anything when Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError is raised' do
      allow(curator).to receive(:curate).and_raise Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError.new('kaboom')
      expect(logger).not_to receive(:error)
      subject.perform
    end

    context 'when feature flag `search_index_curation` is disabled' do
      before do
        stub_feature_flags(search_index_curation: false)
      end

      it 'does not curate anything' do
        expect(curator).not_to receive(:curate)
        expect(subject.perform).to be_falsey
      end
    end
  end

  describe '#logger' do
    it 'logs with Gitlab::Elasticsearch::Logger' do
      expect(subject.send(:logger)).to be_a Gitlab::Elasticsearch::Logger
    end
  end
end
