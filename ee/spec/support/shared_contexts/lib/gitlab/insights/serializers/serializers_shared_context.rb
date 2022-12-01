# frozen_string_literal: true

RSpec.shared_context 'Insights serializers context' do
  let(:input) { build(:insights_issues_by_team_per_month) }

  let(:manage_label) { 'Manage' }
  let(:plan_label) { 'Plan' }
  let(:create_label) { 'Create' }
  let(:undefined_label) { 'undefined' }
  let!(:colors) do
    {
      "#{manage_label}": ::Gitlab::Color.color_for(manage_label).to_s,
      "#{plan_label}": ::Gitlab::Color.color_for(plan_label).to_s,
      "#{create_label}": ::Gitlab::Color.color_for(create_label).to_s,
      "#{undefined_label}": Gitlab::Insights::UNCATEGORIZED_COLOR.to_s
    }
  end

  subject { described_class.present(input) }
end
