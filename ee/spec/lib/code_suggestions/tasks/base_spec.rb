# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodeSuggestions::Tasks::Base, feature_category: :code_suggestions do
  subject { described_class.new }

  describe '#endpoint' do
    it 'raies NotImplementedError' do
      expect { subject.endpoint }.to raise_error(NotImplementedError)
    end
  end

  describe '#body' do
    it 'raies NotImplementedError' do
      expect { subject.body }.to raise_error(NotImplementedError)
    end
  end
end
