# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Insights::Serializers::Chartjs::LineSerializer do
  include_context 'Insights serializers context'

  let!(:expected) do
    {
      labels: ['January 2019', 'February 2019', 'March 2019'],
      datasets: [
        {
          label: manage_label,
          data: [1, 0, 0],
          borderColor: colors[manage_label.to_sym]
        },
        {
          label: plan_label,
          data: [1, 1, 1],
          borderColor: colors[plan_label.to_sym]
        },
        {
          label: create_label,
          data: [1, 0, 1],
          borderColor: colors[create_label.to_sym]
        },
        {
          label: undefined_label,
          data: [0, 0, 1],
          borderColor: colors[undefined_label.to_sym]
        }
      ]
    }.with_indifferent_access
  end

  it 'returns the correct format' do
    expect(subject).to eq(expected)
  end
end
