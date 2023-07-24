# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Storage::CostFactor, feature_category: :consumables_cost_management do
  let(:full_cost) { 1.0 }
  let(:forks_cost_factor) { 0.2 }
  let(:paid_group) { build_group }
  let(:free_group) { build_group(paid: false) }

  before do
    stub_ee_application_setting(namespace_storage_forks_cost_factor: forks_cost_factor)
    stub_ee_application_setting(check_namespace_plan: true)
    stub_feature_flags(namespace_storage_forks_cost_factor: true)
  end

  describe '.cost_factor_for' do
    it 'returns the forks cost factor for a project that is a fork' do
      project = build_fork(group: paid_group)

      expect(described_class.cost_factor_for(project)).to eq(forks_cost_factor)
    end

    it 'returns full cost for a project that is not a fork' do
      project = build_project(group: paid_group)

      expect(described_class.cost_factor_for(project)).to eq(full_cost)
    end

    it 'returns full cost for a private fork in a free namespace' do
      project = build_fork(group: free_group, visibility_level: Gitlab::VisibilityLevel::PRIVATE)

      expect(described_class.cost_factor_for(project)).to eq(full_cost)
    end

    it 'returns full cost when the feature flag is false' do
      stub_feature_flags(namespace_storage_forks_cost_factor: false)
      project = build_fork(group: paid_group)

      expect(described_class.cost_factor_for(project)).to eq(full_cost)
    end

    it 'returns full cost when namespace plans are not checked' do
      stub_ee_application_setting(check_namespace_plan: false)
      project = build_fork(group: paid_group)

      expect(described_class.cost_factor_for(project)).to eq(full_cost)
    end
  end

  describe '.inverted_cost_factor_for_forks' do
    it 'returns the inverse of the cost factor for forks' do
      expect(described_class.inverted_cost_factor_for_forks(paid_group)).to eq(0.8)
    end

    it 'returns the inverse of full cost when the feature flag is false' do
      stub_feature_flags(namespace_storage_forks_cost_factor: false)

      expect(described_class.inverted_cost_factor_for_forks(paid_group)).to eq(0)
    end

    it 'returns the inverse of full cost when namespace plans are not checked' do
      stub_ee_application_setting(check_namespace_plan: false)

      expect(described_class.inverted_cost_factor_for_forks(paid_group)).to eq(0)
    end
  end

  def build_group(paid: true)
    group = build_stubbed(:group)

    allow(group).to receive(:paid?).and_return(paid)

    group
  end

  def build_project(group:, visibility_level: Gitlab::VisibilityLevel::PUBLIC)
    project = build_stubbed(:project, visibility_level: visibility_level)

    allow(project).to receive(:root_ancestor).and_return(group)

    project
  end

  def build_fork(group:, visibility_level: Gitlab::VisibilityLevel::PUBLIC)
    project = build_project(group: group, visibility_level: visibility_level)

    allow(project).to receive(:forked?).and_return(true)

    project
  end
end
