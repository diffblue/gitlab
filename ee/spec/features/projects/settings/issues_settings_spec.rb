# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project settings > Issues', :js, feature_category: :team_planning do
  let(:project) { create(:project, :public) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)

    sign_in(user)
  end

  context 'when Issues are initially enabled' do
    context 'when Pipelines are initially enabled' do
      before do
        visit edit_project_path(project)
      end

      it 'shows the Issues settings' do
        expect(page).to have_content('Set a default description template to be used for new issues.')

        within('.sharing-permissions-form') do
          find('.project-feature-controls[data-for="project[project_feature_attributes][issues_access_level]"] .gl-toggle').click
          click_on('Save changes')
        end

        expect(page).not_to have_content('Set a default description template to be used for new issues.')
      end
    end
  end

  context 'when Issues are initially disabled' do
    before do
      project.project_feature.update_attribute('issues_access_level', ProjectFeature::DISABLED)
      visit edit_project_path(project)
    end

    it 'does not show the Issues settings' do
      expect(page).not_to have_content('Set a default description template to be used for new issues.')

      within('.sharing-permissions-form') do
        find('.project-feature-controls[data-for="project[project_feature_attributes][issues_access_level]"] .gl-toggle').click
        click_on('Save changes')
      end

      expect(page).to have_content('Set a default description template to be used for new issues.')
    end
  end

  context 'issuable default templates feature not available' do
    before do
      stub_licensed_features(issuable_default_templates: false)
    end

    it 'input to configure issue template is not shown' do
      visit edit_project_path(project)

      expect(page).not_to have_selector('#project_issues_template')
    end
  end

  context 'issuable default templates feature is available' do
    before do
      stub_licensed_features(issuable_default_templates: true)
    end

    it 'input to configure issue template is not shown' do
      visit edit_project_path(project)

      expect(page).to have_selector('#project_issues_template')
    end
  end

  context 'when viewing CVE request settings' do
    before do
      allow(::Gitlab).to receive(:com?).and_return(true)

      project.update_column(:visibility_level, Gitlab::VisibilityLevel::PUBLIC)

      project_setting = project.project_setting
      project_setting.cve_id_request_enabled = true
      project_setting.save!

      visit edit_project_path(project)
    end

    it 'CVE ID Request toggle should only be visible if the feature is enabled' do
      expect(page).to have_selector('[data-testid="cve_id_request_toggle"')
    end
  end

  context 'when viewing CVE request settings on GitLab.com' do
    using RSpec::Parameterized::TableSyntax

    where(:project_vis, :cve_enabled, :toggle_checked, :toggle_disabled) do
      :public   | true  | true  | false
      :public   | false | false | false

      :internal | true  | false | true
      :internal | false | false | true

      :private  | true  | false | true
      :private  | false | false | true
    end

    with_them do
      let(:project) do
        create(:project, project_vis, :with_cve_request, cve_request_enabled: cve_enabled)
      end

      before do
        allow(::Gitlab).to receive(:com?).and_return(true)
        visit edit_project_path(project)
      end

      it "CVE ID Request toggle should be correctly visible" do
        toggle_btn = find('[data-testid="cve_id_request_toggle"] button')

        if toggle_disabled
          expect(toggle_btn).to match_css('.is-disabled', wait: 0)
        else
          expect(toggle_btn).not_to match_css('.is-disabled', wait: 0)
        end

        if toggle_checked
          expect(toggle_btn).to match_css('.is-checked', wait: 0)
        else
          expect(toggle_btn).not_to match_css('.is-checked', wait: 0)
        end
      end
    end
  end

  context 'when viewing CVE request settings not on GitLab.com' do
    using RSpec::Parameterized::TableSyntax

    where(:project_vis, :cve_enabled) do
      :public   | true
      :internal | true
      :private  | true
    end

    with_them do
      let(:project) do
        create(:project, project_vis, :with_cve_request, cve_request_enabled: cve_enabled)
      end

      before do
        allow(::Gitlab).to receive(:com?).and_return(false)
        visit edit_project_path(project)
      end

      it "CVE ID Request toggle should never be visible" do
        expect(page).not_to have_selector('[data-testid="cve_id_request_toggle"]')
      end
    end
  end
end
