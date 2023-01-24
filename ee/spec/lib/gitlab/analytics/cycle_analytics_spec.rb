# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics, feature_category: :planning_analytics do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:models) do
    {
      nil: nil,
      issue: create(:issue),
      project_namespace: create(:project).project_namespace,
      group: create(:group)
    }
  end

  where(:model, :enabled_license, :outcome) do
    :nil | nil | false
    :issue | nil | false
    :issue | :cycle_analytics_for_projects | false
    :issue | :cycle_analytics_for_groups | false
    :project_namespace | nil | false
    :project_namespace | :cycle_analytics_for_groups | false
    :project_namespace | :cycle_analytics_for_projects | true
    :group | nil | false
    :group | :cycle_analytics_for_groups | true
    :group | :cycle_analytics_for_projects | false
  end

  with_them do
    subject { described_class.licensed?(models.fetch(model)) }

    before do
      stub_licensed_features(enabled_license => true) if enabled_license
    end

    it { is_expected.to eq(outcome) }
  end
end
