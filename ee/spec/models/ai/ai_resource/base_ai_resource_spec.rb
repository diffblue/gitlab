# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ai::AiResource::BaseAiResource, feature_category: :duo_chat do
  describe '#serialize_for_ai' do
    it 'raises NotImplementedError' do
      expect { described_class.new(nil).serialize_for_ai(_user: nil, _content_limit: nil) }
        .to raise_error(NotImplementedError)
    end
  end
end
