# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::Latest::EpicClassProxy, feature_category: :global_search do
  it 'raises an error when calling elastic_search' do
    expect { described_class.new(Epic, use_separate_indices: true).elastic_search('*') }
      .to raise_error(NotImplementedError)
  end
end
