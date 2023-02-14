# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Automation::Rule, type: :model, feature_category: :no_code_automation do
  describe 'associations' do
    it { is_expected.to belong_to(:namespace).required }
  end

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(TriggerableHooks) }
    it { is_expected.to include_module(StripAttribute) }
  end

  describe 'validations' do
    subject { build(:automation_rule) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive.scoped_to([:namespace_id]) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
  end

  describe 'scopes' do
    describe 'executable' do
      subject { described_class.executable }

      let_it_be(:disabled_rule) { create(:automation_rule, permanently_disabled: true) }
      let_it_be(:executable_rule) { create(:automation_rule, permanently_disabled: false) }

      it { is_expected.to contain_exactly(executable_rule) }
    end
  end

  describe '#name' do
    it 'strips name' do
      rule = described_class.new(name: '  Rule123  ')
      rule.valid?

      expect(rule.name).to eq('Rule123')
    end
  end

  describe 'triggerable hooks' do
    let_it_be_with_reload(:namespace) { create(:project_namespace) }

    {
      issue_hooks: :issues_events,
      merge_request_hooks: :merge_requests_events
    }.each do |scope, trigger_event|
      it "returns rules based on the #{scope} scope" do
        rule = create(:automation_rule, namespace: namespace, trigger_event.to_sym => true)
        expect(described_class.hooks_for(scope)).to contain_exactly(rule)
      end
    end
  end
end
