# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::GlobalSearchIndexingSlis do
  describe '#initialize_slis!' do
    it 'initializes Apdex SLIs for global_search' do
      expect(Gitlab::Metrics::Sli::Apdex).to receive(:initialize_sli).with(
        :global_search_indexing,
        a_kind_of(Array)
      )

      described_class.initialize_slis!
    end
  end

  describe '#record_apdex' do
    context 'when the elapsed time is within the SLI' do
      it 'increments the global_search_indexing SLI as a success' do
        expect(Gitlab::Metrics::Sli::Apdex[:global_search_indexing]).to receive(:increment).with(
          labels: {
            document_type: 'Code'
          },
          success: true
        )

        described_class.record_apdex(
          elapsed: 0.1,
          document_type: 'Code'
        )
      end
    end

    context 'when the elapsed time is not within the SLI' do
      it 'increments the global_search_indexing SLI as a failure' do
        expect(Gitlab::Metrics::Sli::Apdex[:global_search_indexing]).to receive(:increment).with(
          labels: {
            document_type: 'Code'
          },
          success: false
        )

        described_class.record_apdex(
          elapsed: 150,
          document_type: 'Code'
        )
      end
    end
  end
end
