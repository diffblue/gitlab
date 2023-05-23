# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::VertexAi::ModelConfigurations::Base, feature_category: :shared do
  describe '#url' do
    it 'raises MissingConfigurationError' do
      expect { subject.url }.to raise_error(Gitlab::Llm::VertexAi::ModelConfigurations::Base::MissingConfigurationError)
    end
  end
end
