# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::ApplicationSettingsController, feature_category: :shared do
  let(:admin) { create(:admin) }

  describe 'PUT update_microsoft_application', :enable_admin_mode, feature_category: :system_access do
    before do
      sign_in(admin)
    end

    it_behaves_like 'Microsoft application controller actions' do
      let(:path) { update_microsoft_application_admin_application_settings_path }
    end
  end
end
