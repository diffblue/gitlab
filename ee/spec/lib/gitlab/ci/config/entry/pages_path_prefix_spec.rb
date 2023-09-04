# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::PagesPathPrefix, :aggregate_failures, feature_category: :pages do
  let(:entry) { described_class.new(config) }

  describe 'validations' do
    context 'when config value is correct' do
      let(:config) { 'prefix' }

      describe '#config' do
        it 'returns the given value' do
          expect(entry.config).to eq config
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'when the value has a wrong type' do
      let(:config) { { test: true } }

      it 'reports an error' do
        expect(entry.errors).to include 'pages path prefix config should be a string'
      end
    end
  end
end
