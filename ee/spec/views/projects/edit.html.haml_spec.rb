# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/edit' do
  let(:project) { create(:project) }
  let(:user) { create(:admin) }

  before do
    assign(:project, project)

    allow(controller).to receive(:current_user).and_return(user)
    allow(view).to receive_messages(current_user: user,
                                    can?: true,
                                    current_application_settings: Gitlab::CurrentSettings.current_application_settings)
  end

  context 'status checks' do
    context 'feature is not available' do
      before do
        stub_licensed_features(external_status_checks: false)

        render
      end

      it 'hides the status checks area' do
        expect(rendered).not_to have_content('Status check')
      end

      context 'feature is available' do
        before do
          stub_licensed_features(external_status_checks: true)

          render
        end

        it 'shows the status checks area' do
          expect(rendered).to have_content('Status check')
        end
      end
    end
  end

  context 'repository size limit' do
    context 'feature is disabled' do
      before do
        stub_licensed_features(repository_size_limit: false)

        render
      end

      it('renders registration features prompt') do
        expect(rendered).to render_template('shared/_registration_features_discovery_message')
        expect(rendered).to have_field('project_disabled_repository_size_limit', disabled: true)
      end
    end
  end
end
