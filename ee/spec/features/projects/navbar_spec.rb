# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project navbar', feature_category: :navigation do
  include NavbarStructureHelper

  include_context 'project navbar structure'

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, namespace: user.namespace) }

  before do
    project.add_owner(user)

    sign_in(user)

    stub_config(registry: { enabled: false })
    stub_feature_flags(harbor_registry_integration: false)
    stub_feature_flags(combined_analytics_dashboards: false)
    insert_package_nav(_('Deployments'))
    insert_infrastructure_registry_nav
    insert_infrastructure_google_cloud_nav
  end

  context 'when iterations is available' do
    before do
      stub_licensed_features(iterations: true)
    end

    context 'when project is namespaced to a user' do
      before do
        visit project_path(project)
      end

      it_behaves_like 'verified navigation bar'
    end

    context 'when project is namespaced to a group' do
      let_it_be(:group) { create(:group) }
      let_it_be(:project) { create(:project, :repository, group: group) }

      before do
        group.add_developer(user)

        insert_after_sub_nav_item(
          _('Milestones'),
          within: _('Issues'),
          new_sub_nav_item_name: _('Iterations')
        )

        visit project_path(project)
      end

      it_behaves_like 'verified navigation bar'
    end
  end

  context 'when issue analytics is available' do
    before do
      stub_licensed_features(issues_analytics: true)

      insert_after_sub_nav_item(
        _('Code review'),
        within: _('Analytics'),
        new_sub_nav_item_name: _('Issue')
      )

      visit project_path(project)
    end

    it_behaves_like 'verified navigation bar'
  end

  context 'when security dashboard is available' do
    let(:security_and_compliance_nav_item) do
      {
        nav_item: _('Security & Compliance'),
        nav_sub_items: [
          _('Security dashboard'),
          _('Vulnerability report'),
          s_('OnDemandScans|On-demand scans'),
          _('Audit events'),
          _('Configuration')
        ]
      }
    end

    before do
      stub_licensed_features(security_dashboard: true, security_on_demand_scans: true)

      visit project_path(project)
    end

    it_behaves_like 'verified navigation bar'
  end

  context 'when packages are available' do
    before do
      stub_config(packages: { enabled: true }, registry: { enabled: false })

      visit project_path(project)
    end

    it_behaves_like 'verified navigation bar'
  end

  context 'when container registry is available' do
    before do
      stub_config(packages: { enabled: true }, registry: { enabled: true })

      insert_container_nav

      visit project_path(project)
    end

    it_behaves_like 'verified navigation bar'
  end

  context 'when harbor registry is available' do
    let(:harbor_integration) { create(:harbor_integration) }

    before do
      project.update!(harbor_integration: harbor_integration)

      stub_feature_flags(harbor_registry_integration: true)

      insert_harbor_registry_nav(_('Infrastructure Registry'))

      visit project_path(project)
    end

    it_behaves_like 'verified navigation bar'
  end

  context 'when analytics dashboards is available' do
    before do
      stub_feature_flags(combined_analytics_dashboards: true)
      stub_licensed_features(product_analytics: true)

      insert_before_sub_nav_item(
        _('Value stream'),
        within: _('Analytics'),
        new_sub_nav_item_name: _('Dashboards')
      )

      visit project_path(project)
    end

    it_behaves_like 'verified navigation bar'
  end
end
