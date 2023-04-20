# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::TodosHelper do
  include Devise::Test::ControllerHelpers

  describe '#todo_types_options' do
    it 'includes options for an epic todo' do
      expect(helper.todo_types_options).to include(
        { id: 'Epic', text: 'Epic' }
      )
    end
  end

  describe '#todo_target_path' do
    context 'when target is vulnerability' do
      let(:vulnerability) { create(:vulnerability) }
      let(:todo) { create(:todo, target: vulnerability, project: vulnerability.project) }

      subject(:todo_target_path) { helper.todo_target_path(todo) }

      it { is_expected.to eq("/#{todo.project.full_path}/-/security/vulnerabilities/#{todo.target.id}") }
    end
  end

  describe '#todo_author_display?' do
    using RSpec::Parameterized::TableSyntax

    let!(:todo) { create(:todo) }

    subject { helper.todo_author_display?(todo) }

    where(:action, :result) do
      ::Todo::MERGE_TRAIN_REMOVED | false
      ::Todo::ASSIGNED            | true
    end

    with_them do
      before do
        todo.action = action
      end

      it { is_expected.to eq(result) }
    end
  end

  describe '#todo_target_state_pill' do
    subject { helper.todo_target_state_pill(todo) }

    shared_examples 'a rendered state pill' do |attr|
      it 'returns expected html' do
        aggregate_failures do
          expect(subject).to have_css(attr[:css])
          expect(subject).to have_content(attr[:state].capitalize)
        end
      end
    end

    shared_examples 'no state pill' do
      specify { expect(subject).to eq(nil) }
    end

    context 'in epic todo' do
      let(:todo) { create(:todo, target: create(:epic)) }

      it_behaves_like 'no state pill'

      context 'with closed epic' do
        before do
          todo.target.update!(state: 'closed')
        end

        it_behaves_like 'a rendered state pill', css: '.badge-info', state: 'closed'
      end
    end
  end

  describe '#show_todo_state?' do
    let(:closed_epic) { create(:epic, state: 'closed') }
    let(:todo) { create(:todo, target: closed_epic) }

    it 'returns true for a closed epic' do
      expect(helper.show_todo_state?(todo)).to eq(true)
    end
  end

  describe '#todo_groups_requiring_saml_reauth' do
    let_it_be(:restricted_group) do
      create(:group, saml_provider: create(:saml_provider, enabled: true, enforced_sso: true))
    end

    let_it_be(:restricted_group2) do
      create(:group, saml_provider: create(:saml_provider, enabled: true, enforced_sso: true))
    end

    let_it_be(:restricted_subgroup) { create(:group, parent: restricted_group) }
    let_it_be(:unrestricted_group) { create(:group) }

    let_it_be(:epic_todo) { create(:todo, group: restricted_group, target: create(:epic, group: restricted_subgroup)) }

    let_it_be(:restricted_project) { create(:project, namespace: restricted_group2) }

    let_it_be(:issue_todo) do
      create(:todo, project: restricted_project, target: create(:issue, project: restricted_project))
    end

    let_it_be(:issue_todo2) do
      create(:todo, project: restricted_project, target: create(:issue, project: restricted_project))
    end

    let_it_be(:unrestricted_project) { create(:project, namespace: unrestricted_group) }

    let_it_be(:mr_todo) do
      create(:todo, project: unrestricted_project, target: create(:merge_request, source_project: unrestricted_project))
    end

    let_it_be(:user_namespace) { create(:namespace) }
    let_it_be(:user_project) { create(:project, namespace: user_namespace) }
    let_it_be(:user_namespace_issue_todo) do
      create(:todo, project: user_project, target: create(:issue, project: user_project))
    end

    let_it_be(:todos) { [epic_todo, issue_todo, issue_todo2, mr_todo, user_namespace_issue_todo] }

    let(:session) { {} }

    before do
      stub_licensed_features(group_saml: true)
    end

    around do |example|
      Gitlab::Session.with_session(session) do
        example.run
      end
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(dashboard_saml_reauth_support: false)
      end

      it 'returns an empty array of groups' do
        expect(helper.todo_groups_requiring_saml_reauth(todos)).to match_array([])
      end
    end

    it 'returns root groups for todos with targets in SSO enforced groups' do
      expect(helper.todo_groups_requiring_saml_reauth(todos)).to match_array([restricted_group, restricted_group2])
    end

    it 'sends a unique list of groups to the SSO enforcer' do
      expect(::Gitlab::Auth::GroupSaml::SsoEnforcer)
        .to receive(:access_restricted_groups).with([restricted_group, restricted_group2, unrestricted_group], any_args)

      helper.todo_groups_requiring_saml_reauth(todos)
    end
  end
end
