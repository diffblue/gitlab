# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::ValueStreamErrorsSerializer do
  let_it_be(:group) { create(:group) }
  let_it_be(:value_stream) { create(:cycle_analytics_value_stream, name: 'name', namespace: group) }

  subject { described_class.new(value_stream).as_json }

  it 'serializes error on value stream object' do
    value_stream.name = ''

    value_stream.validate

    expect(subject['name']).not_to be_empty
  end

  it 'does not contain stage errors' do
    expect(subject).not_to have_key('stages')
  end

  context 'when nested value stream stages are given' do
    let(:invalid_stage) { build(:cycle_analytics_stage, name: '', namespace: group) }
    let(:valid_stage) { build(:cycle_analytics_stage, namespace: group) }

    before do
      value_stream.stages << invalid_stage
      value_stream.stages << valid_stage
    end

    it 'serializes error on value stream object' do
      value_stream.validate

      stage_errors = subject['stages'][0]
      expect(stage_errors).not_to be_empty
    end
  end

  describe '::STAGE_ATTRIBUTE_REGEX' do
    let(:attribute) { '' }

    subject do
      attribute.match(described_class::STAGE_ATTRIBUTE_REGEX).captures
    end

    context 'extracts the index and the stage attribute name' do
      let(:attribute) { 'stages[0].name' }

      it { is_expected.to eq(%w[0 name]) }

      context 'when large index is given' do
        let(:attribute) { 'stages[11].name' }

        it { is_expected.to eq(%w[11 name]) }
      end
    end
  end
end
