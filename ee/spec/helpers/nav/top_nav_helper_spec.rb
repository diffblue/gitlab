# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nav::TopNavHelper, feature_category: :navigation do
  describe '#top_nav_view_model' do
    let(:user) { build_stubbed(:user) }
    let(:current_user) { user }
    let(:with_environments) { false }
    let(:with_operations) { false }
    let(:with_security) { false }
    let(:with_projects) { false }
    let(:with_geo_secondary) { false }
    let(:with_geo_primary_node_configured) { false }

    subject(:view_model) { helper.top_nav_view_model(project: nil, group: nil) }

    before do
      stub_application_setting(snowplow_enabled: true)

      allow(helper).to receive(:current_user) { current_user }
      allow(helper).to receive(:header_link?).with(anything).and_return(false)

      # Defaulting all `dashboard_nav_link?` calls to false ensures the CE-specific behavior
      # is not tested in this EE spec
      allow(helper).to receive(:dashboard_nav_link?).with(anything).and_return(false)
      allow(helper).to receive(:dashboard_nav_link?).with(:environments) { with_environments }
      allow(helper).to receive(:dashboard_nav_link?).with(:operations) { with_operations }
      allow(helper).to receive(:dashboard_nav_link?).with(:security) { with_security }
      allow(helper).to receive(:dashboard_nav_link?).with(:projects) { with_projects }

      allow(::Gitlab::Geo).to receive(:secondary?) { with_geo_secondary }
      allow(::Gitlab::Geo).to receive(:primary_node_configured?) { with_geo_primary_node_configured }
    end

    context 'with environments' do
      let(:with_environments) { true }

      it 'has expected :primary' do
        expected_header = ::Gitlab::Nav::TopNavMenuHeader.build(
          title: "Your dashboards"
        )
        expected_primary = ::Gitlab::Nav::TopNavMenuItem.build(
          data: {
            qa_selector: 'environment_link',
            **menu_data_tracking_attrs('environments')
          },
          href: '/-/operations/environments',
          icon: 'environment',
          id: 'environments',
          title: 'Environments'
        )
        expect(view_model[:primary]).to eq([expected_header, expected_primary])
      end
    end

    context 'with operations' do
      let(:with_operations) { true }

      it 'has expected :primary' do
        expected_header = ::Gitlab::Nav::TopNavMenuHeader.build(
          title: "Your dashboards"
        )
        expected_primary = ::Gitlab::Nav::TopNavMenuItem.build(
          data: {
            qa_selector: 'operations_link',
            **menu_data_tracking_attrs('operations')
          },
          href: '/-/operations',
          icon: 'cloud-gear',
          id: 'operations',
          title: 'Operations'
        )
        expect(view_model[:primary]).to eq([expected_header, expected_primary])
      end
    end

    context 'with security' do
      let(:with_security) { true }

      it 'has expected :primary' do
        expected_header = ::Gitlab::Nav::TopNavMenuHeader.build(
          title: "Your dashboards"
        )
        expected_primary = ::Gitlab::Nav::TopNavMenuItem.build(
          data: {
            qa_selector: 'security_link',
            **menu_data_tracking_attrs('security')
          },
          href: '/-/security/dashboard',
          icon: 'shield',
          id: 'security',
          title: 'Security'
        )
        expect(view_model[:primary]).to eq([expected_header, expected_primary])
      end
    end

    context 'with geo' do
      let(:with_geo_secondary) { true }
      let(:with_geo_primary_node_configured) { true }
      let(:url) { 'fake_url' }

      before do
        allow(::Gitlab::Geo).to receive_message_chain(:primary_node, :url) { url }
      end

      it 'has expected :secondary' do
        expected_secondary = ::Gitlab::Nav::TopNavMenuItem.build(
          data: {
            qa_selector: 'menu_item_link',
            qa_title: 'Go to primary site',
            **menu_data_tracking_attrs('go_to_primary_site')
          },
          href: url,
          icon: 'location-dot',
          id: 'geo',
          title: 'Go to primary site'
        )
        expect(view_model[:secondary]).to eq([expected_secondary])
      end
    end

    context 'with projects' do
      let(:with_projects) { true }
      let(:projects_view) { view_model[:views][:projects] }

      it 'has expected :primary' do
        expected_header = ::Gitlab::Nav::TopNavMenuHeader.build(
          title: "Switch to"
        )
        expected_primary = ::Gitlab::Nav::TopNavMenuItem.build(
          data: {
            track_action: 'click_dropdown',
            track_label: 'projects_dropdown',
            track_property: 'navigation_top',
            qa_selector: 'projects_dropdown'
          },
          icon: 'project',
          id: 'project',
          title: 'Projects',
          view: 'projects'
        )
        expect(view_model[:primary]).to eq([expected_header, expected_primary])
      end

      context 'when licensed feature is available' do
        before do
          stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)
        end

        it 'has expected :linksPrimary' do
          expected_links_primary = [
            ::Gitlab::Nav::TopNavMenuItem.build(
              data: {
                qa_selector: 'menu_item_link',
                qa_title: 'View all projects',
                **menu_data_tracking_attrs('view_all_projects')
              },
              href: '/dashboard/projects',
              id: 'your',
              title: 'View all projects'
            )
          ]
          expect(projects_view[:linksPrimary]).to eq(expected_links_primary)
        end
      end
    end
  end

  def menu_data_tracking_attrs(label)
    {
      track_label: "menu_#{label}",
      track_action: 'click_dropdown',
      track_property: 'navigation_top'
    }
  end
end
