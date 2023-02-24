# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Search::ReindexingService, feature_category: :global_search do
  subject { described_class.new(**params) }

  let(:params) do
    {
      from: 'from-index',
      to: 'to-index',
      wait_for_completion: true
    }
  end

  let(:client) { ::Gitlab::Search::Client.new }

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
      expect(client).to receive(:reindex).with(**subject.request).and_return :result
      expect(subject.execute).to eq(:result)
    end
  end

  describe '#request' do
    it 'formats request correctly' do
      expect(subject.request).to eq({
        wait_for_completion: params[:wait_for_completion],
        body: {
          source: {
            index: params[:from]
          },
          dest: {
            index: params[:to]
          }
        }
      })
    end

    context 'when overrides are given' do
      subject { described_class.new(overrides: overrides, **params) }

      let(:overrides) do
        {
          wait_for_completion: params[:wait_for_completion],
          body: {
            source: {
              index: 'override'
            }
          }
        }
      end

      it 'formats request correctly' do
        expect(subject.request).to eq({
          wait_for_completion: params[:wait_for_completion],
          body: {
            source: {
              index: overrides.dig(:body, :source, :index)
            },
            dest: {
              index: params[:to]
            }
          }
        })
      end
    end
  end
end
