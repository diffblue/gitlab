# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'epic findable finder' do
  it 'has expected valid params' do
    valid_params = %i[parent_id author_id author_username label_name milestone_title
                      start_date end_date search my_reaction_emoji]
    valid_params += [issues: [], label_name: [], not: {}, or: {}]

    expect(described_class.valid_params).to match_array(valid_params)
  end
end
