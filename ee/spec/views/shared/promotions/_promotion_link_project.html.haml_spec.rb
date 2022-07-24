# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/_promotion_link_project' do
  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:group, name: 'Our group') }

  subject do
    render 'shared/promotions/promotion_link_project', location: 'some_location'

    rendered
  end

  before do
    allow(view).to receive(:current_user).and_return(user)
    @group = namespace
  end

  context 'with namespace plans ' do
    before do
      stub_application_setting(check_namespace_plan: true)
    end

    context 'for namespace admin users' do
      before do
        namespace.add_owner(user)
      end

      it do
        is_expected.to have_link 'Try it for free', href: new_trial_registration_path(glm_source: Gitlab.config.gitlab.host, glm_content: 'some_location')
      end
    end

    context 'for regular users' do
      context 'for groups' do
        it { is_expected.to have_text("Contact an owner of group Our group to upgrade the plan.") }
      end

      context 'for a project in a personal namespace' do
        let_it_be(:user2) { create(:user, name: 'Joe') }
        let_it_be(:project) { create(:project, namespace: user2.namespace) }

        before do
          @project = project
        end

        it { is_expected.to have_text("Contact owner Joe to upgrade the plan.") }
      end
    end
  end

  context 'with instance plans' do
    before do
      stub_application_setting(check_namespace_plan: false)
    end

    context 'for admin users' do
      let_it_be(:user) { create(:admin) }

      context 'with active license' do
        it { is_expected.to have_text('Start GitLab Ultimate trial') }
      end

      context 'with expired license' do
        let_it_be(:expired_license) { create(:license, expired: true) }

        before do
          allow(License).to receive(:current).and_return(expired_license)
        end

        it { is_expected.to have_text('Buy GitLab Enterprise Edition') }
      end
    end

    context 'for regular users' do
      it { is_expected.to have_text('Contact your Administrator to upgrade your license.') }
    end
  end
end
