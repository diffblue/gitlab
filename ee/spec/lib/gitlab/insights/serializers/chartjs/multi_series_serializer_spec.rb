# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Insights::Serializers::Chartjs::MultiSeriesSerializer do
  include_context 'Insights serializers context'

  let!(:expected) do
    {
      labels: ['January 2019', 'February 2019', 'March 2019'],
      datasets: [
        {
          label: manage_label,
          data: [1, 0, 0],
          backgroundColor: colors[manage_label.to_sym]
        },
        {
          label: plan_label,
          data: [1, 1, 1],
          backgroundColor: colors[plan_label.to_sym]
        },
        {
          label: create_label,
          data: [1, 0, 1],
          backgroundColor: colors[create_label.to_sym]
        },
        {
          label: undefined_label,
          data: [0, 0, 1],
          backgroundColor: colors[undefined_label.to_sym]
        }
      ]
    }.with_indifferent_access
  end

  it 'returns the correct format' do
    expect(described_class.present(input)).to eq(expected)
  end

  describe 'wrong input formats' do
    where(:input) do
      [
        [[]],
        [[1, 2, 3]],
        [{ a: :b }],
        [{ a: [:a, 'b'] }]
      ]
    end

    with_them do
      it 'raises an error if the input is not in the correct format' do
        expect { subject }.to raise_error(described_class::WrongInsightsFormatError, /Expected `input` to be of the form `Hash\[Symbol\|String, Hash\[Symbol\|String, Integer\]\]`, .+ given!/)
      end
    end
  end
end
