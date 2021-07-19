# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::TrialHelper do
  using RSpec::Parameterized::TableSyntax

  describe '#should_ask_company_question?' do
    before do
      allow(helper).to receive(:glm_params).and_return(glm_source ? { glm_source: glm_source } : {})
    end

    subject { helper.should_ask_company_question? }

    where(:glm_source, :result) do
      'about.gitlab.com'  | false
      'abouts.gitlab.com' | true
      'about.gitlab.org'  | true
      'about.gitlob.com'  | true
      nil                 | true
    end

    with_them do
      it { is_expected.to eq(result) }
    end
  end

  describe '#glm_params' do
    let(:glm_source) { nil }
    let(:glm_content) { nil }
    let(:params) do
      ActionController::Parameters.new({
        controller: 'FooBar', action: 'stuff', id: '123'
      }.tap do |p|
        p[:glm_source] = glm_source if glm_source
        p[:glm_content] = glm_content if glm_content
      end)
    end

    before do
      allow(helper).to receive(:params).and_return(params)
    end

    subject { helper.glm_params }

    it 'is memoized' do
      expect(helper).to receive(:strong_memoize)

      subject
    end

    where(:glm_source, :glm_content, :result) do
      nil       | nil       | {}
      'source'  | nil       | { glm_source: 'source' }
      nil       | 'content' | { glm_content: 'content' }
      'source'  | 'content' | { glm_source: 'source', glm_content: 'content' }
    end

    with_them do
      it { is_expected.to eq(HashWithIndifferentAccess.new(result)) }
    end
  end

  describe '#namespace_options_for_select' do
    let_it_be(:group1) { create :group }
    let_it_be(:group2) { create :group }

    let(:trial_group_namespaces) { [] }

    let(:new_optgroup_regex) { /<optgroup label="New"><option/ }
    let(:groups_optgroup_regex) { /<optgroup label="Groups"><option/ }

    before do
      allow(helper).to receive(:trial_group_namespaces).and_return(trial_group_namespaces)
    end

    subject { helper.namespace_options_for_select }

    context 'when there is no eligible group' do
      it 'returns just the "New" option group', :aggregate_failures do
        is_expected.to match(new_optgroup_regex)
        is_expected.not_to match(groups_optgroup_regex)
      end
    end

    context 'when only group namespaces are eligible' do
      let(:trial_group_namespaces) { [group1, group2] }

      it 'returns the "New" and "Groups" option groups', :aggregate_failures do
        is_expected.to match(new_optgroup_regex)
        is_expected.to match(groups_optgroup_regex)
      end
    end

    context 'when some group namespaces are eligible' do
      let(:trial_group_namespaces) { [group1, group2] }

      it 'returns the "New", "Groups" option groups', :aggregate_failures do
        is_expected.to match(new_optgroup_regex)
        is_expected.to match(groups_optgroup_regex)
      end
    end
  end

  describe '#trial_selection_intro_text' do
    before do
      allow(helper).to receive(:any_trial_group_namespaces?).and_return(have_group_namespace)
    end

    subject { helper.trial_selection_intro_text }

    where(:have_group_namespace, :text) do
      true  | 'You can apply your trial to a new group or an existing group.'
      false | 'Create a new group to start your GitLab Ultimate trial.'
    end

    with_them do
      it { is_expected.to eq(text) }
    end
  end

  describe '#show_trial_namespace_select?' do
    let_it_be(:have_group_namespace) { false }

    before do
      allow(helper).to receive(:any_trial_group_namespaces?).and_return(have_group_namespace)
    end

    subject { helper.show_trial_namespace_select? }

    it { is_expected.to eq(false) }

    context 'with some trial group namespaces' do
      let_it_be(:have_group_namespace) { true }

      it { is_expected.to eq(true) }
    end
  end

  describe '#show_trial_errors?' do
    shared_examples 'shows errors based on trial generation result' do
      where(:trial_result, :expected_result) do
        nil                | nil
        { success: true }  | false
        { success: false } | true
      end

      with_them do
        it 'show errors when trial generation was unsuccessful' do
          expect(helper.show_trial_errors?(namespace, trial_result)).to eq(expected_result)
        end
      end
    end

    context 'when namespace is nil' do
      let(:namespace) { nil }

      it_behaves_like 'shows errors based on trial generation result'
    end

    context 'when namespace is valid' do
      let(:namespace) { build(:namespace) }

      it_behaves_like 'shows errors based on trial generation result'
    end

    context 'when namespace is invalid' do
      let(:namespace) { build(:namespace, name: 'admin') }

      where(:trial_result, :expected_result) do
        nil                | true
        { success: true }  | true
        { success: false } | true
      end

      with_them do
        it 'show errors regardless of trial generation result' do
          expect(helper.show_trial_errors?(namespace, trial_result)).to eq(expected_result)
        end
      end
    end
  end

  describe '#show_extend_reactivate_trial_button?' do
    let(:namespace) { build(:namespace) }

    subject(:show_extend_reactivate_trial_button) { helper.show_extend_reactivate_trial_button?(namespace) }

    context 'when feature flag is disabled' do
      before do
        allow(namespace).to receive(:can_extend_trial?).and_return(true)
        allow(namespace).to receive(:can_reactivate_trial?).and_return(true)

        stub_feature_flags(allow_extend_reactivate_trial: false)
      end

      it { is_expected.to be_falsey }
    end

    context 'when feature flag is enabled' do
      where(:can_extend_trial, :can_reactivate_trial, :result) do
        false | false | false
        true  | false | true
        false | true  | true
        true  | true  | true
      end

      with_them do
        before do
          stub_feature_flags(allow_extend_reactivate_trial: true)

          allow(namespace).to receive(:can_extend_trial?).and_return(can_extend_trial)
          allow(namespace).to receive(:can_reactivate_trial?).and_return(can_reactivate_trial)
        end

        it { is_expected.to eq(result) }
      end
    end
  end

  describe '#extend_reactivate_trial_button_data' do
    let(:namespace) { build(:namespace, id: 1) }

    subject(:extend_reactivate_trial_button_data) { helper.extend_reactivate_trial_button_data(namespace) }

    before do
      allow(namespace).to receive(:actual_plan_name).and_return('ultimate')
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(allow_extend_reactivate_trial: false)
      end

      context 'when trial can be extended' do
        before do
          allow(namespace).to receive(:trial_active?).and_return(true)
          allow(namespace).to receive(:trial_extended_or_reactivated?).and_return(false)
        end

        it { is_expected.to eq({ namespace_id: 1, plan_name: 'Ultimate', action: nil })}
      end

      context 'when trial can be reactivated' do
        before do
          allow(namespace).to receive(:trial_active?).and_return(false)
          allow(namespace).to receive(:never_had_trial?).and_return(false)
          allow(namespace).to receive(:trial_extended_or_reactivated?).and_return(false)
          allow(namespace).to receive(:free_plan?).and_return(true)
        end

        it { is_expected.to eq({ namespace_id: 1, plan_name: 'Ultimate', action: nil }) }
      end
    end

    context 'when feature flag is enabled' do
      context 'when trial can be extended' do
        before do
          allow(namespace).to receive(:can_extend_trial?).and_return(true)
        end

        it { is_expected.to eq({ namespace_id: 1, plan_name: 'Ultimate', action: 'extend' }) }
      end

      context 'when trial can be reactivated' do
        before do
          allow(namespace).to receive(:can_reactivate_trial?).and_return(true)
        end

        it { is_expected.to eq({ namespace_id: 1, plan_name: 'Ultimate', action: 'reactivate' }) }
      end
    end
  end
end
