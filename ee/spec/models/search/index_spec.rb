# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::Index, feature_category: :global_search do
  describe '.indexed_class' do
    it 'raises a NotImplementedError' do
      expect { described_class.indexed_class }.to raise_error NotImplementedError
    end
  end
end
