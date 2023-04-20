# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Embedding::ApplicationRecord, feature_category: :database do
  describe '.model_name' do
    subject { described_class.model_name }

    it 'removes the prefix' do
      expect(subject.collection).to eq 'application_records'
    end
  end
end
