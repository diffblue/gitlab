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

    context 'when storage is over the notification limit' do
      let_it_be(:root_storage_statistics) do
        create(
          :namespace_root_storage_statistics,
          namespace: user.namespace,
          storage_size: 5.gigabytes
        )
      end

      before do
        set_notification_limit(user.namespace, megabytes: 500)
      end

      it 'displays the banner in the profile page' do
        visit(profile_path)
        expect(page).to have_text storage_banner_text
      end
    end

    context 'when storage is under the notification limit' do
      before do
        set_notification_limit(user.namespace, megabytes: 50000)
      end

      it 'does not display the banner in the group page' do
        visit(profile_path)
        expect(page).not_to have_text storage_banner_text
      end
    end
  end
end
