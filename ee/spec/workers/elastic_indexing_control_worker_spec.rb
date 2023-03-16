# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ElasticIndexingControlWorker, feature_category: :global_search do
  subject { described_class.new }

  describe '#perform' do
    context 'indexing is unpaused' do
      before do
        expect(Elastic::IndexingControl).to receive(:non_cached_pause_indexing?).and_return(false)
      end

      it 'calls resume_processing!' do
        expect(Elastic::IndexingControl).to receive(:resume_processing!)

        subject.perform
      end
    end

    context 'indexing is paused' do
      before do
        expect(Elastic::IndexingControl).to receive(:non_cached_pause_indexing?).and_return(true)
      end

      it 'raises an exception' do
        expect { subject.perform }.to raise_error(RuntimeError, /elasticsearch_pause_indexing/)
      end
    end
  end
end
