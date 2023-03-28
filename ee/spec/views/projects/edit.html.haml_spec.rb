# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/edit' do
  let(:project) { create(:project) }
  let(:user) { create(:admin) }

  before do
    assign(:project, project)

    allow(controller).to receive(:current_user).and_return(user)
    allow(view).to receive_messages(
      current_user: user,
      can?: true,
      current_application_settings: Gitlab::CurrentSettings.current_application_settings
    )
  end

  describe 'prompt user about registration features' do
    context 'with no license and service ping disabled' do
      before do
        allow(License).to receive(:current).and_return(nil)
        stub_application_setting(usage_ping_enabled: false)
      end

      it_behaves_like 'renders registration features prompt', :project_disabled_repository_size_limit
      it_behaves_like 'renders registration features settings link'
    end

    context 'with a valid license and service ping disabled' do
      before do
        license = build(:license)
        allow(License).to receive(:current).and_return(license)
        stub_application_setting(usage_ping_enabled: false)
      end

      it_behaves_like 'does not render registration features prompt', :project_disabled_repository_size_limit
    end
  end
end
