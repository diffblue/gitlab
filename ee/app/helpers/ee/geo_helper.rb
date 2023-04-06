# frozen_string_literal: true

module EE
  module GeoHelper
    STATUS_ICON_NAMES_BY_STATE = {
        synced: 'check-circle-filled',
        pending: 'status_pending',
        failed: 'status_failed',
        never: 'status_notfound'
    }.freeze

    def self.current_node_human_status
      return s_('Geo|primary') if ::Gitlab::Geo.primary?
      return s_('Geo|secondary') if ::Gitlab::Geo.secondary?

      s_('Geo|misconfigured')
    end

    def geo_sites_vue_data
      {
        replicable_types: replicable_types.to_json,
        new_site_url: new_admin_geo_node_path,
        geo_sites_empty_state_svg: image_path("illustrations/empty-state/geo-empty.svg")
      }
    end

    def node_namespaces_options(namespaces)
      namespaces.map { |g| { id: g.id, text: g.full_name } }
    end

    def node_selected_namespaces_to_replicate(node)
      node.namespaces.map(&:human_name).sort.join(', ')
    end

    def selective_sync_types_json
      options = {
        ALL: {
          label: s_('Geo|All projects'),
          value: ''
        },
        NAMESPACES: {
          label: s_('Geo|Projects in certain groups'),
          value: 'namespaces'
        },
        SHARDS: {
          label: s_('Geo|Projects in certain storage shards'),
          value: 'shards'
        }
      }

      options.to_json
    end

    def node_class(node)
      klass = []
      klass << 'js-geo-secondary-node' if node.secondary?
      klass << 'node-disabled' unless node.enabled?
      klass
    end

    def geo_registry_status(registry)
      status_type = case registry.synchronization_state
                    when :synced then 'gl-text-green-500'
                    when :pending then 'gl-text-orange-500'
                    when :failed then 'gl-text-red-500'
                    else 'gl-text-gray-500'
                    end

      content_tag(:div, class: status_type, data: { testid: 'project-status-icon' }) do
        icon = geo_registry_status_icon(registry)
        text = geo_registry_status_text(registry)

        [icon, text].join(' ').html_safe
      end
    end

    def geo_registry_status_icon(registry)
      sprite_icon(STATUS_ICON_NAMES_BY_STATE.fetch(registry.synchronization_state, 'status_notfound'))
    end

    def geo_registry_status_text(registry)
      case registry.synchronization_state
      when :never
        _('Never')
      when :failed
        _('Failed')
      when :pending
        if registry.pending_synchronization?
          s_('Geo|Pending synchronization')
        elsif registry.pending_verification?
          s_('Geo|Pending verification')
        else
          # should never reach this state, unless we introduce new behavior
          _('Unknown')
        end
      when :synced
        _('Synced')
      else
        # should never reach this state, unless we introduce new behavior
        _('Unknown')
      end
    end

    def remove_tracking_entry_modal_data(path)
      {
        path: path,
        method: 'delete',
        modal_attributes: {
          title: s_('Geo|Remove tracking database entry'),
          message: s_('Geo|Tracking database entry will be removed. Are you sure?'),
          okVariant: 'danger',
          okTitle: s_('Geo|Remove entry')
        }
      }
    end

    def resync_all_button(projects_count, limit)
      # This is deprecated and Hard Coded for Projects.
      # All new replicable types should be using geo_replicable/app.vue

      resync_all_projects_modal_data = {
        path: resync_all_admin_geo_projects_url,
        method: 'post',
        modal_attributes: {
          title: projects_count > 1 ? sprintf(s_('Geo|Resync all %{projects_count} projects'), { projects_count: format_project_count(projects_count, limit) }) : s_('Geo|Resync project'),
          message: s_('Geo|This will resync all projects. It may take some time to complete. Are you sure you want to continue?'),
          okTitle: s_('Geo|Resync all'),
          size: 'sm'
        }
      }

      render Pajamas::ButtonComponent.new(button_options: { class: 'js-confirm-modal-button gl-mr-3', data: resync_all_projects_modal_data }) do
        s_("Geo|Resync all")
      end
    end

    def reverify_all_button(projects_count, limit)
      # This is deprecated and Hard Coded for Projects.
      # All new replicable types should be using geo_replicable/app.vue

      reverify_all_projects_modal_data = {
        path: reverify_all_admin_geo_projects_url,
        method: 'post',
        modal_attributes: {
          title: projects_count > 1 ? sprintf(s_('Geo|Reverify all %{projects_count} projects'), { projects_count: format_project_count(projects_count, limit) }) : s_('Geo|Reverify project'),
          message: s_('Geo|This will reverify all projects. It may take some time to complete. Are you sure you want to continue?'),
          okTitle: s_('Geo|Reverify all'),
          size: 'sm'
        }
      }

      render Pajamas::ButtonComponent.new(button_options: { class: 'js-confirm-modal-button gl-mr-3', data: reverify_all_projects_modal_data }) do
        s_("Geo|Reverify all")
      end
    end

    def format_project_count(projects_count, limit)
      if projects_count >= limit
        number_with_delimiter(limit - 1) + "+"
      else
        number_with_delimiter(projects_count)
      end
    end

    def replicable_types
      # Hard Coded Legacy Types, we will want to remove these when they are added to SSF
      replicable_types = [
        {
          data_type: 'repository',
          data_type_title: _('Git'),
          title: _('Repository'),
          title_plural: _('Repositories'),
          name: 'repository',
          name_plural: 'repositories',
          custom_replication_url: 'admin/geo/replication/projects',
          verification_enabled: true
        },
        {
          data_type: 'repository',
          data_type_title: _('Git'),
          title: _('Wiki'),
          title_plural: _('Wikis'),
          name: 'wiki',
          name_plural: 'wikis',
          no_replication_view: true,
          verification_enabled: true
        },
        {
          data_type: 'repository',
          data_type_title: _('Git'),
          title: _('Design repository'),
          title_plural: _('Design repositories'),
          name: 'design_repository',
          name_plural: 'design_repositories',
          custom_replication_url: 'admin/geo/replication/designs',
          verification_enabled: false
        }
      ]

      replicable_types.reject! { |t| t[:name] == 'wiki' } if ::Geo::ProjectWikiRepositoryReplicator.enabled?

      # Adds all the SSF Data Types automatically
      enabled_replicator_classes.each do |replicator_class|
        replicable_types.push(
          {
            data_type: replicator_class.data_type,
            data_type_title: replicator_class.data_type_title,
            title: replicator_class.replicable_title,
            title_plural: replicator_class.replicable_title_plural,
            name: replicator_class.replicable_name,
            name_plural: replicator_class.replicable_name_plural,
            verification_enabled: replicator_class.verification_enabled?
          }
        )
      end

      replicable_types
    end

    def enabled_replicator_classes
      ::Gitlab::Geo.enabled_replicator_classes
    end

    def geo_filter_nav_options(replicable_controller, replicable_name)
      [
        {
          value: '',
          text: sprintf(s_('Geo|All %{replicable_name}'), { replicable_name: replicable_name }),
          href: url_for(controller: replicable_controller)
        },
        {
          value: 'pending',
          text: s_('Geo|In progress'),
          href: url_for(controller: replicable_controller, sync_status: 'pending')
        },
        {
          value: 'failed',
          text: s_('Geo|Failed'),
          href: url_for(controller: replicable_controller, sync_status: 'failed')
        },
        {
          value: 'synced',
          text: s_('Geo|Synced'),
          href: url_for(controller: replicable_controller, sync_status: 'synced')
        }
      ]
    end

    def prepare_error_app_data(registry)
      {
        synchronizationFailure: registry.last_repository_sync_failure,
        verificationFailure: registry.last_repository_verification_failure,
        retryCount: registry.repository_retry_count || 0
      }.to_json
    end
  end
end
