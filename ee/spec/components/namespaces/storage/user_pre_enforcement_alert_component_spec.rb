# frozen_string_literal: true
require "spec_helper"

RSpec.describe Namespaces::Storage::UserPreEnforcementAlertComponent, :saas, type: :component do
  include ActionView::Helpers::NumberHelper
  include StorageHelper

  let_it_be_with_refind(:user) { create(:user) }

  subject(:component) { described_class.new(context: user.namespace, user: user) }

  before do
    stub_ee_application_setting(should_check_namespace_plan: true)
    stub_ee_application_setting(enforce_namespace_storage_limit: true)
  end

  context 'when user namespace' do
    before do
      allow(user.namespace).to receive(:user_namespace?).and_return(true)

      create(
        :namespace_root_storage_statistics,
        namespace: user.namespace,
        storage_size: 5.gigabytes
      )
    end

    context 'when a notification limit has not been set' do
      it 'does not include used storage in the banner text' do
        render_inline(component)

        expect(page).not_to have_text storage_counter(5.gigabytes)
      end
    end

    context 'when a notification limit has been set' do
      before do
        create(:plan_limits, plan: user.namespace.root_ancestor.actual_plan, notification_limit: 500)
      end

      it 'includes used storage in the banner text' do
        render_inline(component)

        expect(page).to have_text storage_counter(5.gigabytes)
      end

      it 'includes the correct navigation instruction in the banner text' do
        render_inline(component)

        expect(page).to have_text "View and manage your usage from User settings > Usage quotas"
      end
    end
  end
end
