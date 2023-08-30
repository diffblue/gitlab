# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Search::ReindexingService, feature_category: :global_search do
  let(:from_index) { 'from-index' }
  let(:to_index) { 'to-index' }
  let(:query) { 'test' }
  let(:slice) { 1 }
  let(:max_slices) { 10 }
  let(:wait_for_completion) { true }
  let(:params) do
    {
      from: from_index,
      to: to_index,
      query: query,
      wait_for_completion: wait_for_completion,
      slice: slice,
      max_slices: max_slices
    }
  end

  let_it_be(:client) { ::Gitlab::Search::Client.new }

  subject { described_class.new(**params) }

  describe '.execute' do
    it 'passes arguments to instance' do
      expect(described_class).to receive(:new).with(**params).and_return(subject)
      expect(subject).to receive(:execute)
      described_class.execute(**params)
    end
  end

  describe '#execute' do
    it 'passes correct arguments to search client' do
      expect(::Gitlab::Search::Client).to receive(:new).and_return client
      expect(client).to receive(:reindex).with({
        wait_for_completion: wait_for_completion,
        body: {
          source: {
            index: from_index,
            query: query,
            slice: {
              id: slice,
              max: max_slices
            }
          },
          dest: {
            index: to_index
          }
        }
      }).and_return :result
      expect(subject.execute).to eq(:result)
    end
  end

  describe '#request' do
    it 'formats request correctly' do
      expect(subject.request).to eq({
        wait_for_completion: wait_for_completion,
        body: {
          source: {
            index: from_index,
            query: query,
            slice: {
              id: slice,
              max: max_slices
            }
          },
          dest: {
            index: to_index
          }
        }
      })
    end

    context 'when `from` param is not provided' do
      let(:params) do
        {
          to: to_index,
          query: query,
          wait_for_completion: wait_for_completion,
          slice: slice,
          max_slices: max_slices
        }
      end

      it 'raises an error' do
        expect { subject.request }.to raise_error(ArgumentError, 'from is required')
      end
    end

    context 'when `to` param is not provided' do
      let(:params) do
        {
          from: from_index,
          query: query,
          wait_for_completion: wait_for_completion,
          slice: slice,
          max_slices: max_slices
        }
      end

      it 'raises an error' do
        expect { subject.request }.to raise_error(ArgumentError, 'to is required')
      end
    end

    context 'when optional params are not provided' do
      let(:params) do
        {
          from: from_index,
          to: to_index,
          wait_for_completion: wait_for_completion
        }
      end

      it 'removes keys with nil values' do
        expect(subject.request).to eq({
          wait_for_completion: wait_for_completion,
          body: {
            source: {
              index: from_index
            },
            dest: {
              index: to_index
            }
          }
        })
      end
    end

    context 'when manual slicing options provided' do
      context 'when slice is invalid' do
        let(:params) do
          {
            from: from_index,
            to: to_index,
            query: query,
            wait_for_completion: wait_for_completion,
            slice: described_class::INVALID_SLICE_ID,
            max_slices: max_slices
          }
        end

        it 'raises an error' do
          expect { subject.request }.to raise_error(ArgumentError, 'slice must be > 0')
        end
      end

      context 'when max_slices is invalid' do
        let(:params) do
          {
            from: from_index,
            to: to_index,
            query: query,
            wait_for_completion: wait_for_completion,
            slice: slice,
            max_slices: described_class::INVALID_SLICE_MAX
          }
        end

        it 'raises an error' do
          expect { subject.request }.to raise_error(ArgumentError, 'max_slices must be > 1')
        end
      end

      context 'when slice is missing' do
        let(:params) do
          {
            from: from_index,
            to: to_index,
            query: query,
            wait_for_completion: wait_for_completion,
            max_slices: max_slices
          }
        end

        it 'raises an error' do
          expect { subject.request }.to raise_error(ArgumentError, 'slice must be > 0')
        end
      end

      context 'when max_slices is missing' do
        let(:params) do
          {
            from: from_index,
            to: to_index,
            query: query,
            wait_for_completion: wait_for_completion,
            slice: slice
          }
        end

        it 'raises an error' do
          expect { subject.request }.to raise_error(ArgumentError, 'max_slices must be > 1')
        end
      end
    end

    context 'when overrides are given' do
      let(:wait_for_completion) { false }
      let(:from_index) { 'override' }
      let(:overrides) do
        {
          wait_for_completion: wait_for_completion,
          body: {
            source: {
              index: from_index
            }
          }
        }
      end

      subject { described_class.new(overrides: overrides, **params) }

      it 'formats request correctly' do
        expect(subject.request).to eq({
          wait_for_completion: wait_for_completion,
          body: {
            source: {
              index: from_index
            },
            dest: {
              index: to_index
            }
          }
        })
      end
    end
  end
end
