# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::FreeUserCap::PersonalUsageQuotaLimitationsAlertComponent, :saas, :aggregate_failures,
  type: :component do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:original_namespace_owner) { namespace.owner }
  let_it_be(:project) { create(:project, namespace: namespace) }
  let_it_be(:user, refind: true) { create(:user) }

  let(:user_owns_namespace?) { true }
  let(:free_user_cap_enabled?) { true }
  let(:title) { _('Your project has limited quotas and features') }

  before do
    stub_application_setting(check_namespace_plan: true)
    stub_feature_flags(free_user_cap: free_user_cap_enabled?)

    if user_owns_namespace?
      namespace.update!(owner: user)
    else
      namespace.update!(owner: original_namespace_owner)
    end
  end

  subject(:component) { described_class.new(project: project, user: user) }

  shared_examples 'does not render the banner' do
    it 'does not render the banner' do
      render_inline(component)

      expect(rendered_component).not_to have_content(title)
    end
  end

  context 'when user is authorized to see the banner' do
    context 'and has not yet dismissed the banner 1' do
      it 'renders the banner' do
        render_inline(component)

        expect(rendered_component).to have_content(title)
        expect(rendered_component).to have_selector('.js-project-usage-limitations-callout')
        expect(rendered_component).to have_link('moving this project to a group',
            href: help_page_path('tutorials/move_personal_project_to_a_group'))
        expect(rendered_component).to have_link('manage the members of this project',
            href: project_project_members_path(project))
      end
    end

    context 'but has already dismissed the banner' do
      let(:feature_name) { 'personal_project_limitations_banner' }

      before do
        create(:callout, feature_name: feature_name, user: user)
      end

      include_examples 'does not render the banner'
    end
  end

  context 'when the free_user_cap feature flag is not enabled' do
    let(:free_user_cap_enabled?) { false }

    include_examples 'does not render the banner'
  end

  context 'when project belongs to a group' do
    let(:group) { create(:group) }
    let(:project) { create(:project, group: group) }

    before do
      group.add_owner(user)
    end

    include_examples 'does not render the banner'
  end

  context 'when user is not authorized to see the banner' do
    let(:user_owns_namespace?) { false }

    include_examples 'does not render the banner'
  end

  context 'when user does not exist' do
    let(:user) { nil }
    let(:user_owns_namespace?) { false }

    include_examples 'does not render the banner'
  end
end
