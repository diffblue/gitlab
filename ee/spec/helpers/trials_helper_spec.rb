# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TrialsHelper, feature_category: :purchase do
  using RSpec::Parameterized::TableSyntax

  describe '#create_lead_form_data' do
    let(:user) { build_stubbed(:user, user_detail: build_stubbed(:user_detail, organization: '_org_')) }

    let(:extra_params) do
      {
        first_name: '_params_first_name_',
        last_name: '_params_last_name_',
        company_name: '_params_company_name_',
        company_size: '_company_size_',
        phone_number: '1234',
        country: '_country_',
        state: '_state_'
      }
    end

    let(:params) do
      ActionController::Parameters.new(extra_params.merge(glm_source: '_glm_source_', glm_content: '_glm_content_'))
    end

    before do
      allow(helper).to receive(:params).and_return(params)
      allow(helper).to receive(:current_user).and_return(user)
    end

    it 'provides expected form data' do
      keys = extra_params.keys + [:submit_path]

      expect(helper.create_lead_form_data.keys.map(&:to_sym)).to match_array(keys)
    end

    it 'allows overriding data with params' do
      expect(helper.create_lead_form_data).to match(a_hash_including(extra_params))
    end

    context 'when params are empty' do
      let(:extra_params) { {} }

      it 'uses the values from current user' do
        current_user_attributes = {
          first_name: user.first_name,
          last_name: user.last_name,
          company_name: user.organization
        }

        expect(helper.create_lead_form_data).to match(a_hash_including(current_user_attributes))
      end
    end
  end

  describe '#create_company_form_data' do
    let(:extra_params) do
      {
        trial: 'true',
        role: '_params_role_',
        registration_objective: '_params_registration_objective_',
        jobs_to_be_done_other: '_params_jobs_to_be_done_other'
      }
    end

    let(:params) do
      ActionController::Parameters.new(extra_params)
    end

    before do
      allow(helper).to receive(:params).and_return(params)
    end

    it 'provides expected form data' do
      keys = [:submit_path]

      expect(helper.create_company_form_data.keys.map(&:to_sym)).to match_array(keys)
    end

    it 'allows overriding data with params' do
      submit_path = {
        submit_path: "/users/sign_up/company?#{extra_params.to_query}"
      }

      expect(helper.create_company_form_data).to match(submit_path)
    end
  end

  describe '#should_ask_company_question?' do
    before do
      allow(helper).to receive(:glm_params).and_return(glm_source ? { glm_source: glm_source } : {})
    end

    subject { helper.should_ask_company_question? }

    where(:glm_source, :result) do
      'about.gitlab.com'  | false
      'learn.gitlab.com'  | false
      'docs.gitlab.com'   | false
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

  describe '#glm_source' do
    let(:host) { ::Gitlab.config.gitlab.host }

    it 'return gitlab config host' do
      glm_source = helper.glm_source

      expect(glm_source).to eq(host)
    end
  end

  describe '#namespace_options_for_listbox' do
    let_it_be(:group1) { create :group }
    let_it_be(:group2) { create :group }

    let(:trialable_group_namespaces) { [] }

    let(:new_optgroup) do
      {
        text: _('New'),
        options: [
          {
            text: _('Create group'),
            value: '0'
          }
        ]
      }
    end

    let(:groups_optgroup) do
      {
        text: _('Groups'),
        options: trialable_group_namespaces.map { |n| { text: n.name, value: n.id.to_s } }
      }
    end

    before do
      allow(helper).to receive(:trialable_group_namespaces).and_return(trialable_group_namespaces)
    end

    subject { helper.namespace_options_for_listbox }

    context 'when there is no eligible group' do
      it 'returns just the "New" option group', :aggregate_failures do
        is_expected.to match_array([new_optgroup])
      end
    end

    context 'when only group namespaces are eligible' do
      let(:trialable_group_namespaces) { [group1, group2] }

      it 'returns the "New" and "Groups" option groups', :aggregate_failures do
        is_expected.to match_array([new_optgroup, groups_optgroup])
        expect(subject[1][:options].length).to be(2)
      end
    end

    context 'when some group namespaces are eligible' do
      let(:trialable_group_namespaces) { [group2] }

      it 'returns the "New", "Groups" option groups', :aggregate_failures do
        is_expected.to match_array([new_optgroup, groups_optgroup])
        expect(subject[1][:options].length).to be(1)
      end
    end
  end

  describe '#trial_selection_intro_text' do
    before do
      allow(helper).to receive(:any_trialable_group_namespaces?).and_return(have_group_namespace)
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
      allow(helper).to receive(:any_trialable_group_namespaces?).and_return(have_group_namespace)
    end

    subject { helper.show_trial_namespace_select? }

    it { is_expected.to eq(false) }

    context 'with some trial group namespaces' do
      let_it_be(:have_group_namespace) { true }

      it { is_expected.to eq(true) }
    end
  end

  describe '#only_trialable_group_namespace' do
    subject { helper.only_trialable_group_namespace }

    let_it_be(:group1) { create :group }
    let_it_be(:group2) { create :group }

    let(:trialable_group_namespaces) { [group1] }

    before do
      allow(helper).to receive(:trialable_group_namespaces).and_return(trialable_group_namespaces)
    end

    context 'when there is 1 namespace group eligible' do
      it { is_expected.to eq(group1) }
    end

    context 'when more than 1 namespace is eligible' do
      let(:trialable_group_namespaces) { [group1, group2] }

      it { is_expected.to be_nil }
    end

    context 'when there are 0 namespace groups eligible' do
      let(:trialable_group_namespaces) { [] }

      it { is_expected.to be_nil }
    end
  end
end
