# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::IndexCurationWorker do
  include StubFeatureFlags
  subject { described_class.new }

  let(:curator) { ::Gitlab::Search::IndexCurator }
  let(:logger) { ::Gitlab::Elasticsearch::Logger.build }

  describe '#perform' do
    before do
      allow(subject).to receive(:logger).and_return(logger)
    end

    it 'calls on the curator' do
      expect(curator).to receive(:curate)
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
