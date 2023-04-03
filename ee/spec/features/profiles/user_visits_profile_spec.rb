# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User visits their profile', feature_category: :user_profile do
  include NamespaceStorageHelpers

  let_it_be_with_refind(:user) { create(:user) }

  before do
    stub_ee_application_setting(should_check_namespace_plan: true)
    stub_ee_application_setting(enforce_namespace_storage_limit: true)

    sign_in(user)
  end

  describe 'storage_enforcement_banner', :js do
    let_it_be(:storage_banner_text) { "A namespace storage limit will soon be enforced" }

    before do
      stub_feature_flags(namespace_storage_limit_bypass_date_check: false)
    end

    context 'with storage_enforcement_date set' do
      let_it_be(:storage_enforcement_date) { Date.today + 30 }
      let_it_be(:root_storage_statistics) do
        create(
          :namespace_root_storage_statistics,
          namespace: user.namespace,
          storage_size: 5.gigabytes
        )
      end

      before do
        allow_next_found_instance_of(Namespaces::UserNamespace) do |user_namespace|
          allow(user_namespace).to receive(:storage_enforcement_date).and_return(storage_enforcement_date)
        end
        create(:plan_limits, plan: user.namespace.root_ancestor.actual_plan, notification_limit: 500)
      end

      it 'displays the banner in the profile page' do
        visit(profile_path)
        expect(page).to have_text storage_banner_text
      end

      context 'when the user has previously dismissed and the storage_enforcement_date threshold has changed' do
        it 'displays the banner' do
          visit(profile_path)
          expect(page).to have_text storage_banner_text
          find('.js-storage-enforcement-banner [data-testid="close-icon"]').click
          page.refresh
          expect(page).not_to have_text storage_banner_text

          storage_enforcement_date = Date.today + 13
          allow_next_found_instance_of(Namespaces::UserNamespace) do |user_namespace|
            allow(user_namespace).to receive(:storage_enforcement_date).and_return(storage_enforcement_date)
          end
          page.refresh
          expect(page).to have_text storage_banner_text
        end
      end

      it 'does not display the banner if the namespace does not reach the notification_limit' do
        visit(profile_path)
        find('.js-storage-enforcement-banner [data-testid="close-icon"]').click

        set_notification_limit(user.namespace, megabytes: 6000)

        page.refresh

        expect(page).not_to have_text storage_banner_text
      end

      context 'with a storage_enforcement_date in past' do
        let(:storage_enforcement_date) { Date.today - 1 }

        before do
          allow(user.namespace).to receive(:storage_enforcement_date).and_return(storage_enforcement_date)
        end

        it 'does not display the banner' do
          visit(profile_path)
          expect(page).not_to have_text storage_banner_text
        end
      end
    end

    context 'with storage_enforcement_date not set' do
      before do
        allow_next_found_instance_of(Namespaces::UserNamespace) do |user_namespace|
          allow(user_namespace).to receive(:storage_enforcement_date).and_return(nil)
        end
      end

      it 'does not display the banner in the group page' do
        visit(profile_path)
        expect(page).not_to have_text storage_banner_text
      end
    end
  end
end
