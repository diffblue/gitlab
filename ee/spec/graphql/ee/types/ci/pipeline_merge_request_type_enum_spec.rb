# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PipelineMergeRequestEventType'] do
  it 'has specific values' do
    expect(described_class.values).to match a_hash_including(
      'MERGE_TRAIN' => have_attributes(value: :merge_train)
    )
  end
end
