# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::DastConfiguration do
  let(:entry) { described_class.new(config) }

  shared_examples_for 'a valid entry' do
    describe '#value' do
      it 'returns configuration' do
        expect(entry.value).to eq(config)
      end
    end

    describe '#valid?' do
      it 'is valid' do
        expect(entry).to be_valid
      end
    end
  end

  describe 'validation' do
    context 'when both site and scanner configuration are present' do
      let(:config) { { site_profile: 'Site profile', scanner_profile: 'Scanner profile' } }

      it_behaves_like 'a valid entry'
    end

    context 'when only the site profile is present' do
      let(:config) { { site_profile: 'Site profile' } }

      it_behaves_like 'a valid entry'
    end

    context 'when only the scanner profile is present' do
      let(:config) { { scanner_profile: 'Scanner profile' } }

      it_behaves_like 'a valid entry'
    end

    context 'when no keys are present' do
      let(:config) { {} }

      it_behaves_like 'a valid entry'
    end

    context 'when entry value is not correct' do
      describe '#errors' do
        context 'when there is an unknown key present' do
          let(:config) { { foo: 'Foo profile' } }

          it 'reports error' do
            expect(entry.errors).to include 'dast configuration config contains unknown keys: foo'
          end
        end
      end
    end
  end
end
