# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::GenericMetric do
  context 'with custom fallback' do
    subject do
      Class.new(described_class) do
        fallback(-2)
        value { Gitlab::Database.version }
      end.new(time_frame: 'none')
    end

    describe '#value' do
      it 'gives the correct value' do
        expect(subject.value).to eq(Gitlab::Database.version )
      end

      context 'when raising an exception' do
        it 'return the custom fallback' do
          expect(Gitlab::Database).to receive(:version).and_raise('Error')
          expect(subject.value).to eq(-2)
        end
      end
    end
  end

  context 'with default fallback' do
    subject do
      Class.new(described_class) do
        value { Gitlab::Database.version }
      end.new(time_frame: 'none')
    end

    describe '#value' do
      it 'gives the correct value' do
        expect(subject.value).to eq(Gitlab::Database.version )
      end

      context 'when raising an exception' do
        it 'return the custom fallback' do
          expect(Gitlab::Database).to receive(:version).and_raise('Error')
          expect(subject.value).to eq(-1)
        end
      end
    end
  end
end
