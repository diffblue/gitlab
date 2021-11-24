# frozen_string_literal: true

RSpec.shared_examples 'multi store feature flags' do |use_multi_store, use_primary_store|
  context "with feature flag :#{use_multi_store} is enabled" do
    before do
      stub_feature_flags(use_multi_store => true)
    end

    it 'multi store is enabled' do
      expect(subject.multi_store_enabled?).to be true
    end
  end

  context "with feature flag :#{use_multi_store} is disabled" do
    before do
      stub_feature_flags(use_multi_store => false)
    end

    it 'multi store is disabled' do
      expect(subject.multi_store_enabled?).to be false
    end
  end

  context "with feature flag :#{use_primary_store} is enabled" do
    before do
      stub_feature_flags(use_primary_store => true)
    end

    it 'primary store is enabled' do
      expect(subject.primary_store_enabled?).to be true
    end
  end

  context "with feature flag :#{use_primary_store} is disabled" do
    before do
      stub_feature_flags(use_primary_store => false)
    end

    it 'primary store is disabled' do
      expect(subject.primary_store_enabled?).to be false
    end
  end
end
