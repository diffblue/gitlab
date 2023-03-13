# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group navbar', feature_category: :subgroups do
  include NavbarStructureHelper
  include WaitForRequests
  include WikiHelpers

  include_context 'group navbar structure'

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  context 'for maintainers' do
    before do
      group.add_maintainer(user)
      stub_group_wikis(false)
      stub_feature_flags(harbor_registry_integration: false)
      stub_feature_flags(observability_group_tab: false)
      sign_in(user)

      insert_package_nav(_('Kubernetes'))
      insert_after_nav_item(_('Analytics'), new_nav_item: settings_for_maintainer_nav_item)
    end

    context 'when devops adoption analytics is available' do
      before do
        stub_licensed_features(group_level_devops_adoption: true)

        insert_after_sub_nav_item(
          _('Contribution'),
          within: _('Analytics'),
          new_sub_nav_item_name: _('DevOps adoption')
        )

        visit group_path(group)
      end

      it_behaves_like 'verified navigation bar'
    end

    context 'when productivity analytics is available' do
      before do
        stub_licensed_features(productivity_analytics: true)

        insert_after_sub_nav_item(
          _('Contribution'),
          within: _('Analytics'),
          new_sub_nav_item_name: _('Productivity')
        )

        visit group_path(group)
      end

      it_behaves_like 'verified navigation bar'
    end

    context 'when value stream analytics is available' do
      before do
        stub_licensed_features(cycle_analytics_for_groups: true)

        insert_before_sub_nav_item(
          _('Contribution'),
          within: _('Analytics'),
          new_sub_nav_item_name: _('Value stream')
        )

        visit group_path(group)
      end

      it_behaves_like 'verified navigation bar'

      it 'redirects to value stream when Analytics item is clicked' do
        page.within('.sidebar-top-level-items') do
          find('.shortcuts-analytics').click
        end

        wait_for_requests

        expect(page).to have_current_path(group_analytics_cycle_analytics_path(group))
      end
    end

    context 'when epics are available' do
      before do
        stub_licensed_features(epics: true)

        insert_after_nav_item(
          _('Group information'),
          new_nav_item: {
            nav_item: _('Epics'),
            nav_sub_items: [
              _('List'),
              _('Boards'),
              _('Roadmap')
            ]
          }
        )

        visit group_path(group)
      end

      it_behaves_like 'verified navigation bar'
    end

    context 'when packages are available' do
      before do
        stub_config(packages: { enabled: true }, registry: { enabled: false })

        visit group_path(group)
      end

      context 'when container registry is available' do
        before do
          stub_config(registry: { enabled: true })

          insert_after_sub_nav_item(
            _('Package Registry'),
            within: _('Packages and registries'),
            new_sub_nav_item_name: _('Container Registry')
          )

          visit group_path(group)
        end

        it_behaves_like 'verified navigation bar'
      end

      context 'when customer relations feature is enabled' do
        let(:group) { create(:group, :crm_enabled) }

        before do
          insert_customer_relations_nav(_('Analytics'))

          visit group_path(group)
        end

        it_behaves_like 'verified navigation bar'
      end

      context 'when customer relations feature enabled but subgroup' do
        let(:group) { create(:group, :crm_enabled, parent: create(:group)) }

        before do
          visit group_path(group)
        end

        it_behaves_like 'verified navigation bar'
      end
    end

    context 'when iterations are available' do
      before do
        stub_licensed_features(iterations: true)

        visit group_path(group)
      end

      it_behaves_like 'verified navigation bar'
    end

    context 'when group wiki is available' do
      before do
        stub_group_wikis(true)

        insert_after_nav_item(
          _('Analytics'),
          new_nav_item: {
            nav_item: _('Wiki'),
            nav_sub_items: []
          }
        )
        visit group_path(group)
      end

      it_behaves_like 'verified navigation bar'
    end

    context 'when harbor registry is available' do
      let(:harbor_integration) { create(:harbor_integration, group: group, project: nil) }

      before do
        group.update!(harbor_integration: harbor_integration)

        stub_feature_flags(harbor_registry_integration: true)

        insert_harbor_registry_nav(_('Package Registry'))

        visit group_path(group)
      end

      it_behaves_like 'verified navigation bar'
    end

    context 'when observability tab is enabled' do
      before do
        stub_feature_flags(observability_group_tab: true)

        insert_observability_nav

        visit group_path(group)
      end

      it_behaves_like 'verified navigation bar'
    end
  end

  context 'for owners', :saas do
    before do
      group.add_owner(user)
      stub_group_wikis(false)
      stub_feature_flags(harbor_registry_integration: false)
      stub_feature_flags(observability_group_tab: false)
      stub_licensed_features(domain_verification: true)
      sign_in(user)
      insert_package_nav(_('Kubernetes'))
    end

    describe 'structure' do
      before do
        insert_after_nav_item(_('Security and Compliance'), new_nav_item: ci_cd_nav_item)
        insert_after_nav_item(_('Analytics'), new_nav_item: settings_nav_item)

        visit group_path(group)
      end

      it_behaves_like 'verified navigation bar'
    end

    context 'when SAML SSO is available' do
      before do
        stub_licensed_features(group_saml: true, domain_verification: true)

        insert_after_nav_item(_('Security and Compliance'), new_nav_item: ci_cd_nav_item)
        insert_after_nav_item(_('Analytics'), new_nav_item: settings_nav_item)
        insert_after_sub_nav_item(
          s_('UsageQuota|Usage Quotas'),
          within: _('Settings'),
          new_sub_nav_item_name: _('SAML SSO')
        )

        visit group_path(group)
      end

      it_behaves_like 'verified navigation bar'
    end

    context 'when security dashboard is available' do
      let(:security_and_compliance_nav_item) do
        {
          nav_item: _('Security and Compliance'),
          nav_sub_items: [
            _('Security dashboard'),
            _('Vulnerability report'),
            _('Compliance report'),
            _('Audit events')
          ]
        }
      end

      before do
        stub_licensed_features(
          security_dashboard: true,
          group_level_compliance_dashboard: true,
          domain_verification: true
        )

        insert_after_nav_item(_('Security and Compliance'), new_nav_item: ci_cd_nav_item)
        insert_after_nav_item(_('Analytics'), new_nav_item: settings_nav_item)

        visit group_path(group)
      end

      it_behaves_like 'verified navigation bar'
    end
  end
end
