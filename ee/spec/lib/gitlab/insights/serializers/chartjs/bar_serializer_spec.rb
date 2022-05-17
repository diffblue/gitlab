# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Insights::Serializers::Chartjs::BarSerializer do
  include_context 'Insights serializers context'

  it 'returns the correct format' do
    input = build(:insights_issues_by_team)
    expected = {
      labels: [manage_label, plan_label, create_label, undefined_label],
      datasets: [
        {
          label: nil,
          data: [1, 3, 2, 1],
          backgroundColor: [colors[manage_label.to_sym], colors[plan_label.to_sym], colors[create_label.to_sym], colors[undefined_label.to_sym]]
        }
      ]
    }.with_indifferent_access

    expect(described_class.present(input)).to eq(expected)
  end

  describe 'wrong input formats' do
    where(:input) do
      [
        [[]],
        [[1, 2, 3]],
        [{ a: :b }]
      ]
    end

    with_them do
      it 'raises an error if the input is not in the correct format' do
        expect { described_class.present(input) }.to raise_error(described_class::WrongInsightsFormatError, /Expected `input` to be of the form `Hash\[Symbol\|String, Integer\]`, .+ given!/)
      end
    end
  end
end
