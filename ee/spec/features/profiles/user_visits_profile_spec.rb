# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User visits their profile', feature_category: :user_profile do
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
          storage_size: ::EE::Gitlab::Namespaces::Storage::Enforcement::FREE_NAMESPACE_STORAGE_CAP
        )
      end

      before do
        allow_next_found_instance_of(Namespaces::UserNamespace) do |user_namespace|
          allow(user_namespace).to receive(:storage_enforcement_date).and_return(storage_enforcement_date)
        end
      end

      it 'displays the banner in the profile page' do
        visit(profile_path)
        expect(page).to have_text storage_banner_text
      end

      it 'does not display the banner if user has previously closed unless threshold has changed' do
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
