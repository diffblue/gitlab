# frozen_string_literal: true

module EE
  module Sidebars
    module Groups
      module Menus
        module SettingsMenu
          extend ::Gitlab::Utils::Override
          include ::Gitlab::Utils::StrongMemoize

          override :configure_menu_items
          def configure_menu_items
            return false unless super

            insert_item_after(:integrations, webhooks_menu_item)
            add_item(ldap_sync_menu_item)
            add_item(saml_sso_menu_item)
            add_item(saml_group_links_menu_item)
            add_item(usage_quotas_menu_item)
            add_item(billing_menu_item)
            add_item(reporting_menu_item)

            true
          end

          private

          def ldap_sync_menu_item
            unless ldap_sync_enabled?
              return ::Sidebars::NilMenuItem.new(item_id: :ldap_sync)
            end

            ::Sidebars::MenuItem.new(
              title: _('LDAP Synchronization'),
              link: group_ldap_group_links_path(context.group),
              active_routes: { path: 'ldap_group_links#index' },
              item_id: :ldap_sync
            )
          end

          def ldap_sync_enabled?
            ::Gitlab::Auth::Ldap::Config.group_sync_enabled? &&
              can?(context.current_user, :admin_ldap_group_links, context.group)
          end

          def saml_sso_menu_item
            unless saml_sso_enabled?
              return ::Sidebars::NilMenuItem.new(item_id: :saml_sso)
            end

            ::Sidebars::MenuItem.new(
              title: _('SAML SSO'),
              link: group_saml_providers_path(context.group),
              active_routes: { path: 'saml_providers#show' },
              item_id: :saml_sso
            )
          end

          def saml_sso_enabled?
            can?(context.current_user, :admin_group_saml, context.group) &&
              administration_nav_item_disabled?
          end

          def saml_group_links_menu_item
            unless can?(context.current_user, :admin_saml_group_links, context.group)
              return ::Sidebars::NilMenuItem.new(item_id: :saml_group_links)
            end

            ::Sidebars::MenuItem.new(
              title: s_('GroupSAML|SAML Group Links'),
              link: group_saml_group_links_path(context.group),
              active_routes: { path: 'saml_group_links#index' },
              item_id: :saml_group_links
            )
          end

          def webhooks_menu_item
            unless webhooks_enabled?
              return ::Sidebars::NilMenuItem.new(item_id: :webhooks)
            end

            ::Sidebars::MenuItem.new(
              title: _('Webhooks'),
              link: group_hooks_path(context.group),
              active_routes: { path: 'hooks#index' },
              item_id: :webhooks
            )
          end

          def webhooks_enabled?
            context.group.licensed_feature_available?(:group_webhooks) ||
              context.show_promotions
          end

          def usage_quotas_menu_item
            unless usage_quotas_enabled?
              return ::Sidebars::NilMenuItem.new(item_id: :usage_quotas)
            end

            ::Sidebars::MenuItem.new(
              title: s_('UsageQuota|Usage Quotas'),
              link: group_usage_quotas_path(context.group),
              active_routes: { path: 'usage_quotas#index' },
              item_id: :usage_quotas
            )
          end

          def usage_quotas_enabled?
            ::License.feature_available?(:usage_quotas) &&
              context.group.parent.nil? &&
              administration_nav_item_disabled?
          end

          def billing_menu_item
            unless billing_enabled?
              return ::Sidebars::NilMenuItem.new(item_id: :billing)
            end

            ::Sidebars::MenuItem.new(
              title: _('Billing'),
              link: group_billings_path(context.group),
              active_routes: { path: 'billings#index' },
              item_id: :billing
            )
          end

          def billing_enabled?
            ::Gitlab::CurrentSettings.should_check_namespace_plan? &&
              administration_nav_item_disabled?
          end

          def administration_nav_item_disabled?
            strong_memoize(:administration_nav_item_disabled) do
              ::Feature.disabled?(:group_administration_nav_item, context.group)
            end
          end

          def reporting_menu_item
            unless context.group.unique_project_download_limit_enabled?
              return ::Sidebars::NilMenuItem.new(item_id: :reporting)
            end

            ::Sidebars::MenuItem.new(
              title: s_('GroupSettings|Reporting'),
              link: group_settings_reporting_path(context.group),
              active_routes: { path: 'reporting#show' },
              item_id: :reporting
            )
          end
        end
      end
    end
  end
end
