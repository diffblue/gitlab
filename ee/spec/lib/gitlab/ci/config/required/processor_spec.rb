# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Required::Processor, feature_category: :pipeline_composition do
  subject { described_class.new(config).perform }

  let(:config) { { image: 'image:1.0.0' } }

  context 'when feature is available' do
    before do
      stub_licensed_features(required_ci_templates: true)

      stub_application_setting(required_instance_ci_template: required_ci_template_name)
    end

    context 'when template is set' do
      context 'when template can not be found' do
        let(:required_ci_template_name) { 'invalid_template_name' }

        it 'raises an error' do
          expect { subject }.to raise_error(Gitlab::Ci::Config::Required::Processor::RequiredError)
        end
      end

      context 'when template can be found' do
        let(:required_ci_template_name) { 'Android' }

        it 'merges the template content with the config' do
          expect(subject).to include(image: 'eclipse-temurin:17-jdk-jammy')
        end
      end
    end

    context 'when template is not set' do
      let(:required_ci_template_name) { nil }

      it 'returns the unmodified config' do
        expect(subject).to eq(config)
      end
    end

    context 'when template is empty string' do
      let(:required_ci_template_name) { "" }

      it 'returns the unmodified config' do
        expect(subject).to eq(config)
      end
    end
  end

  context 'when feature is not available' do
    before do
      stub_licensed_features(required_ci_templates: false)
    end

    it 'returns the unmodified config' do
      expect(subject).to eq(config)
    end
  end
end
