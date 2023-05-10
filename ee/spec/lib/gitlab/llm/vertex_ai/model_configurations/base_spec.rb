# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::VertexAi::ModelConfigurations::Base, feature_category: :shared do
  describe '#url' do
    it 'raises NotImplementedError' do
      expect { subject.url }.to raise_error(NotImplementedError)
    end
  end

  describe '#host' do
    it 'raises NotImplementedError' do
      expect { subject.host }.to raise_error(NotImplementedError)
    end
  end
end
