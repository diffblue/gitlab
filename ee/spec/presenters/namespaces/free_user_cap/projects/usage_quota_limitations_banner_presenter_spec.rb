# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::FreeUserCap::Projects::UsageQuotaLimitationsBannerPresenter, :saas do
  include Gitlab::Routing.url_helpers

  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:project) { create(:project, namespace: namespace) }

  # NOTE: We need to create a fresh user for each spec here to avoid issues with the @callouts_by_feature_name
  # instance variable cache on an existing user in the case that #dismissed_callout? has already been called before a
  # hew `user_callouts` record is created.
  let(:user) { create(:user) }
  let(:user_owns_namespace?) { true }
  let(:free_user_cap_enabled?) { true }
  let(:feature_name) { 'personal_project_limitations_banner' }

  before do
    stub_application_setting(check_namespace_plan: true)
    stub_feature_flags(free_user_cap: true)
    namespace.update!(owner: user) if user_owns_namespace?
  end

  subject(:presenter) { described_class.new(project, current_user: user) }

  describe '#feature_name' do
    it 'returns the name associated with the Users::Callout model' do
      expect(presenter.feature_name).to eq(feature_name)
    end
  end

  describe '#visible?' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:namespace_project) { create(:project, namespace: namespace) }
    let_it_be(:group_project) { create(:project, group: create(:group)) }

    subject(:visible?) { presenter.visible?}

    before do
      allow(presenter).to receive(:dismissed?).and_return(banner_dismissed?)
      allow(presenter).to receive(:free_user_cap_enforced?).and_return(free_user_cap_enforced?)
    end

    where(:user_owns_namespace?, :free_user_cap_enforced?, :banner_dismissed?, :project, :expected) do
      true  | true  | true  | ref(:namespace_project) | false
      true  | true  | false | ref(:namespace_project) | true
      true  | false | true  | ref(:namespace_project) | false
      true  | false | false | ref(:namespace_project) | false
      false | true  | true  | ref(:namespace_project) | false
      false | true  | false | ref(:namespace_project) | false
      false | false | true  | ref(:namespace_project) | false
      false | false | false | ref(:namespace_project) | false

      true  | true  | true  | ref(:group_project) | false
      true  | true  | false | ref(:group_project) | false
      true  | false | true  | ref(:group_project) | false
      true  | false | false | ref(:group_project) | false
      false | true  | true  | ref(:group_project) | false
      false | true  | false | ref(:group_project) | false
      false | false | true  | ref(:group_project) | false
      false | false | false | ref(:group_project) | false
    end

    with_them do
      it { is_expected.to eq(expected) }
    end
  end

  describe '#dismissed?' do
    subject(:dismissed?) { presenter.dismissed? }

    context 'when no user is provided' do
      let(:user) { nil }
      let(:user_owns_namespace?) { false }

      it 'raises a NoMethodError error' do
        expect { dismissed? }.to raise_error(NoMethodError)
      end
    end

    context 'when a user is provided' do
      context 'and the user has not already dismissed the callout' do
        it { is_expected.to be_falsey }
      end

      context 'and the user has already dismissed the callout' do
        before do
          create(:callout, feature_name: feature_name, user: user)
        end

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#alert_component_attributes' do
    it 'returns a hash of attributes to pass to the Pajamas::AlertComponent instance' do
      expect(presenter.alert_component_attributes).to match({
        alert_options: {
          class: a_string_including('js-project-usage-limitations-callout'),
          data: {
            dismiss_endpoint: callouts_path,
            feature_id: feature_name
          }
        },
        title: String,
        variant: :tip
      })
    end
  end

  describe '#title_text' do
    it 'returns the translated title text' do
      expect(presenter.title_text).to eq(_('Your project has limited quotas and features'))
    end
  end

  describe '#body_text' do
    it 'returns the translated body text' do
      expect(presenter.body_text).to eq(_(
        '%{strong_start}%{project_name}%{strong_end} is a personal project, so you can’t upgrade to a paid plan or ' \
        'start a free trial to lift these limits. We recommend %{move_to_group_link}moving this project to a group' \
        '%{end_link} to unlock these options. You can %{manage_members_link}manage the members of this project' \
        '%{end_link}, but don’t forget that all unique members in your personal namespace %{strong_start}' \
        '%{namespace_name}%{strong_end} count towards total seats in use.'
      ) % {
        strong_start: '<strong>'.html_safe,
        strong_end: '</strong>'.html_safe,
        end_link: '</a>'.html_safe,
        move_to_group_link: '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % {
          url: help_page_path('tutorials/move_personal_project_to_a_group')
        },
        manage_members_link: '<a href="%{url}">'.html_safe % { url: project_project_members_path(project) },
        project_name: project.name,
        namespace_name: project.namespace.name
      })
    end
  end
end
