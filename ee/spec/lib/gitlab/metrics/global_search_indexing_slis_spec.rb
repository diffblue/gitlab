# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::GlobalSearchIndexingSlis, feature_category: :global_search do
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
            document_type: 'Code',
            indexed_by: 'indexer'
          },
          success: true
        )

        described_class.record_apdex(elapsed: 0.1, document_type: 'Code')
      end
    end

    context 'when the elapsed time is not within the SLI' do
      before do
        stub_const("#{described_class.name}::CODE_INDEXING_TARGET_S", 2.0)
      end

      it 'increments the global_search_indexing SLI as a failure' do
        expect(Gitlab::Metrics::Sli::Apdex[:global_search_indexing]).to receive(:increment).with(
          labels: {
            document_type: 'Code',
            indexed_by: 'indexer'
          },
          success: false
        )

        described_class.record_apdex(elapsed: 10, document_type: 'Code')
      end
    end

    context 'for document_type targets' do
      using RSpec::Parameterized::TableSyntax

      before do
        stub_const("#{described_class.name}::CODE_INDEXING_TARGET_S", 20.0)
        stub_const("#{described_class.name}::CONTENT_INDEXING_TARGET_S", 1.0)
      end

      where(:document_type, :indexed_by, :elapsed, :expected_result) do
        'Code'          | 'indexer' | 5 | true
        'Wiki'          | 'indexer' | 5 | true
        'MergeRequest'  | 'rails'   | 5 | false
        'User'          | 'rails'   | 5 | false
        'Issue'         | 'rails'   | 5 | false
      end

      with_them do
        it 'uses the correct target' do
          expect(Gitlab::Metrics::Sli::Apdex[:global_search_indexing]).to receive(:increment).with(
            labels: {
              document_type: document_type,
              indexed_by: indexed_by
            },
            success: expected_result
          )

          described_class.record_apdex(elapsed: elapsed, document_type: document_type)
        end
      end
    end
  end

  describe '#record_bytes_per_second_apdex' do
    using RSpec::Parameterized::TableSyntax

    before do
      stub_const("#{described_class.name}::INDEXED_BYTES_PER_SECOND_TARGET", 200.0)
    end

    where(:throughput, :expected_success) do
      20.0  | false
      300.0 | true
    end

    with_them do
      it 'increments the global_search_indexing SLI with the correct success field' do
        expect(Gitlab::Metrics::Sli::Apdex[:global_search_indexing]).to receive(:increment).with(
          labels: {
            document_type: 'Database',
            indexed_by: 'rails'
          },
          success: expected_success
        )

        described_class.record_bytes_per_second_apdex(throughput: throughput)
      end
    end
  end
end
