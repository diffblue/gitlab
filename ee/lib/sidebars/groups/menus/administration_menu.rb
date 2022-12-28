# frozen_string_literal: true

module Sidebars
  module Groups
    module Menus
      class AdministrationMenu < ::Sidebars::Menu
        include Gitlab::Utils::StrongMemoize

        override :configure_menu_items
        def configure_menu_items
          return false unless administration_menu_enabled?

          add_item(saml_sso_menu_item)
          add_item(usage_quotas_menu_item)
          add_item(billing_menu_item)

          true
        end

        override :title
        def title
          _('Administration')
        end

        override :sprite_icon
        def sprite_icon
          'admin'
        end

        private

        def administration_menu_enabled?
          ::Feature.enabled?(:group_administration_nav_item, context.group) &&
            context.group.root? &&
            can?(context.current_user, :admin_group, context.group)
        end

        def saml_sso_menu_item
          unless can?(context.current_user, :admin_group_saml, context.group)
            return ::Sidebars::NilMenuItem.new(item_id: :saml_sso)
          end

          ::Sidebars::MenuItem.new(
            title: _('SAML SSO'),
            link: group_saml_providers_path(context.group),
            active_routes: { path: 'saml_providers#show' },
            item_id: :saml_sso
          )
        end

        def usage_quotas_menu_item
          unless context.group.usage_quotas_enabled?
            return ::Sidebars::NilMenuItem.new(item_id: :usage_quotas)
          end

          ::Sidebars::MenuItem.new(
            title: s_('UsageQuota|Usage Quotas'),
            link: group_usage_quotas_path(context.group),
            active_routes: { path: 'usage_quotas#index' },
            item_id: :usage_quotas
          )
        end

        def billing_menu_item
          unless ::Gitlab::CurrentSettings.should_check_namespace_plan?
            return ::Sidebars::NilMenuItem.new(item_id: :billing)
          end

          ::Sidebars::MenuItem.new(
            title: _('Billing'),
            link: group_billings_path(context.group),
            active_routes: { path: 'billings#index' },
            item_id: :billing
          )
        end
      end
    end
  end
end
