# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project > Settings > Analytics -> Instrumentation instructions', :js, feature_category: :product_analytics_visualization do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group).tap { |g| g.add_owner(user) } }
  let_it_be(:project) { create(:project, namespace: group) }

  before do
    sign_in(user)
  end

  context 'without correct license' do
    before do
      stub_licensed_features(product_analytics: false)
      stub_feature_flags(product_analytics_admin_settings: true, product_analytics_dashboards: true)

      visit project_settings_analytics_path(project)
    end

    it 'does not show instrumentation instructions' do
      expect(page).not_to have_content s_('View instrumentation instructions')
    end
  end

  context 'without correct feature flags enabled' do
    where(:product_analytics_admin_settings, :product_analytics_dashboards) do
      true | false
      false | true
      false | false
    end

    with_them do
      before do
        stub_licensed_features(product_analytics: true)
        stub_feature_flags(product_analytics_admin_settings: product_analytics_admin_settings,
          product_analytics_dashboards: product_analytics_dashboards)

        visit project_settings_analytics_path(project)
      end

      it 'does not show instrumentation instructions' do
        expect(page).not_to have_content s_('View instrumentation instructions')
      end
    end
  end

  context 'with valid license and feature flags' do
    before do
      stub_licensed_features(product_analytics: true)
      stub_feature_flags(product_analytics_admin_settings: true, product_analytics_dashboards: true)
    end

    context 'when project is not yet onboarded' do
      let(:project_settings) { { product_analytics_instrumentation_key: nil } }

      before do
        project.project_setting.update!(project_settings)
        project.reload
        visit project_settings_analytics_path(project)
      end

      it 'shows link to onboarding flow' do
        expect(page).to have_content(
          s_('You need to set up product analytics before your application can be instrumented.'))
        expect(page).to have_link('set up product analytics',
          href: project_analytics_dashboards_path(project, vueroute: 'product-analytics-onboarding'))
      end
    end

    context 'when project is onboarded' do
      let(:instrumentation_key) { 456 }
      let(:collector_host) { 'https://collector.example.com' }

      before do
        stub_application_setting({ product_analytics_data_collector_host: collector_host })
        project.project_setting.update!({ product_analytics_instrumentation_key: instrumentation_key })
        project.reload
        visit project_settings_analytics_path(project)
      end

      it 'shows instrumentation key' do
        fieldset = page.find('fieldset', text: s_('SDK application ID'))
        expect(fieldset.find("input").value).to eq(instrumentation_key.to_s)
      end

      it 'shows collector host' do
        fieldset = page.find('fieldset', text: s_('SDK host'))
        expect(fieldset.find("input").value).to eq(collector_host)
      end

      it 'shows instrumentation setup instructions' do
        expect(page).to have_button(s_("View instrumentation instructions"))

        click_button s_("View instrumentation instructions")

        expect(page).to have_content(
          s_("1. Add the NPM package to your package.json using your preferred package manager"))
        expect(page).to have_content(s_("2. Import the new package into your JS code"))
        expect(page).to have_content(s_("3. Initiate the tracking"))
        expect(page).to have_content(s_("Add the script to the page and assign the client SDK to window"))
      end
    end
  end
end
