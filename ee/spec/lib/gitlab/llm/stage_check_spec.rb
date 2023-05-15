# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::StageCheck, feature_category: :no_category do # rubocop: disable RSpec/InvalidFeatureCategory
  before do
    allow(Gitlab).to receive(:com?).and_return(true)
    stub_ee_application_setting(should_check_namespace_plan: true)
    stub_licensed_features(ai_features: true)
  end

  describe ".available?" do
    let(:feature_name) { :summarize_comments }
    let(:group) { create(:group_with_plan, :private, plan: :ultimate_plan) }

    context 'with experiment feature' do
      before do
        stub_const("#{described_class}::EXPERIMENTAL_FEATURES", [feature_name])
      end

      context 'when experimental setting is false' do
        it 'returns false' do
          group.namespace_settings.update!(experiment_features_enabled: false)
          expect(described_class.available?(group, feature_name)).to eq(false)
        end
      end

      context 'when experimental setting is true' do
        it 'returns true' do
          group.namespace_settings.update!(experiment_features_enabled: true)
          expect(described_class.available?(group, feature_name)).to eq(true)
        end
      end
    end

    context 'with beta feature' do
      before do
        stub_const("#{described_class}::BETA_FEATURES", [feature_name])
      end

      context 'when experimental setting is false' do
        it 'returns false' do
          group.namespace_settings.update!(experiment_features_enabled: false)
          expect(described_class.available?(group, feature_name)).to eq(false)
        end
      end

      context 'when experimental setting is true' do
        it 'returns true' do
          group.namespace_settings.update!(experiment_features_enabled: true)
          expect(described_class.available?(group, feature_name)).to eq(true)
        end
      end
    end

    context 'with third party feature' do
      before do
        stub_const("#{described_class}::EXPERIMENTAL_FEATURES", [feature_name])
        stub_const("#{described_class}::THIRD_PARTY_FEATURES", [feature_name])
      end

      context 'when third party feature setting is false' do
        it 'returns false' do
          group.namespace_settings.update!(third_party_ai_features_enabled: false, experiment_features_enabled: true)
          expect(described_class.available?(group, feature_name)).to eq(false)
        end
      end

      context 'when third party feature setting is true' do
        it 'returns true' do
          group.namespace_settings.update!(third_party_ai_features_enabled: true, experiment_features_enabled: true)
          expect(described_class.available?(group, feature_name)).to eq(true)
        end
      end
    end

    context 'with feature in two groups' do
      before do
        stub_const("#{described_class}::THIRD_PARTY_FEATURES", [feature_name])
        stub_const("#{described_class}::EXPERIMENTAL_FEATURES", [feature_name])
      end

      context 'when third party setting is false and experimental setting is true' do
        it 'returns false' do
          group.namespace_settings.update!(third_party_ai_features_enabled: false, experiment_features_enabled: true)

          expect(described_class.available?(group, feature_name)).to eq(false)
        end
      end

      context 'when third party setting is true and experimental setting is true' do
        it 'returns true' do
          group.namespace_settings.update!(third_party_ai_features_enabled: true, experiment_features_enabled: true)
          expect(described_class.available?(group, feature_name)).to eq(true)
        end
      end

      context 'when experimental setting is false and third party setting is true' do
        it 'returns true' do
          group.namespace_settings.update!(third_party_ai_features_enabled: true, experiment_features_enabled: false)
          expect(described_class.available?(group, feature_name)).to eq(false)
        end
      end
    end
  end
end
