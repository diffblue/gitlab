# frozen_string_literal: true

module EE
  module GeoHelper
    STATUS_ICON_NAMES_BY_STATE = {
        synced: 'check',
        pending: 'clock',
        failed: 'warning-solid',
        never: 'status_notfound'
    }.freeze

    def self.current_node_human_status
      return s_('Geo|primary') if ::Gitlab::Geo.primary?
      return s_('Geo|secondary') if ::Gitlab::Geo.secondary?

      s_('Geo|misconfigured')
    end

    def node_vue_list_properties
      version, revision =
        if ::Gitlab::Geo.primary?
          [::Gitlab::VERSION, ::Gitlab.revision]
        else
          status = ::Gitlab::Geo.primary_node&.status

          [status&.version, status&.revision]
        end

      {
        primary_version: version.to_s,
        primary_revision: revision.to_s,
        replicable_types: replicable_types.to_json,
        new_node_url: new_admin_geo_node_path,
        geo_nodes_empty_state_svg: image_path("illustrations/empty-state/geo-empty.svg")
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

    def toggle_node_button(node)
      btn_class, title, data =
        if node.enabled?
          ['warning', 'Disable', { confirm: 'Disabling a node stops the sync process. Are you sure?' }]
        else
          %w[success Enable]
        end

      link_to title,
              toggle_admin_geo_node_path(node),
              method: :post,
              class: "btn btn-sm btn-#{btn_class}",
              title: title,
              data: data
    end

    def geo_registry_status(registry)
      status_type = case registry.synchronization_state
                    when :failed then
                      'text-danger-500'
                    when :synced then
                      'text-success-600'
                    end

      content_tag(:div, class: "#{status_type}") do
        icon = geo_registry_status_icon(registry)
        text = geo_registry_status_text(registry)

        [icon, text].join(' ').html_safe
      end
    end

    def geo_registry_status_icon(registry)
      sprite_icon(STATUS_ICON_NAMES_BY_STATE.fetch(registry.synchronization_state, 'warning-solid'))
    end

    def geo_registry_status_text(registry)
      case registry.synchronization_state
      when :never
        s_('Geo|Not synced yet')
      when :failed
        s_('Geo|Failed')
      when :pending
        if registry.pending_synchronization?
          s_('Geo|Pending synchronization')
        elsif registry.pending_verification?
          s_('Geo|Pending verification')
        else
          # should never reach this state, unless we introduce new behavior
          s_('Geo|Unknown state')
        end
      when :synced
        s_('Geo|In sync')
      else
        # should never reach this state, unless we introduce new behavior
        s_('Geo|Unknown state')
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

    def resync_all_button
      # This is deprecated and Hard Coded for Projects.
      # All new replicable types should be using geo_replicable/app.vue

      resync_all_projects_modal_data = {
        path: resync_all_admin_geo_projects_url,
        method: 'post',
        modal_attributes: {
          title: s_('Geo|Resync all projects'),
          message: s_('Geo|This will resync all projects. It may take some time to complete. Are you sure you want to continue?'),
          okTitle: s_('Geo|Resync all'),
          size: 'sm'
        }
      }

      button_tag(s_("Geo|Resync all"), type: "button", class: 'gl-button btn btn-default gl-mr-3 js-confirm-modal-button', data: resync_all_projects_modal_data)
    end

    def reverify_all_button
      # This is deprecated and Hard Coded for Projects.
      # All new replicable types should be using geo_replicable/app.vue

      reverify_all_projects_modal_data = {
        path: reverify_all_admin_geo_projects_url,
        method: 'post',
        modal_attributes: {
          title: s_('Geo|Reverify all projects'),
          message: s_('Geo|This will reverify all projects. It may take some time to complete. Are you sure you want to continue?'),
          okTitle: s_('Geo|Reverify all'),
          size: 'sm'
        }
      }

      button_tag(s_("Geo|Reverify all"), type: "button", class: 'gl-button btn btn-default gl-mr-3 js-confirm-modal-button', data: reverify_all_projects_modal_data)
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
          secondary_view: true
        },
        {
          data_type: 'repository',
          data_type_title: _('Git'),
          title: _('Wiki'),
          title_plural: _('Wikis'),
          name: 'wiki',
          name_plural: 'wikis'
        },
        {
          data_type: 'blob',
          data_type_title: _('File'),
          title: _('Container repository'),
          title_plural: _('Container repositories'),
          name: 'container_repository',
          name_plural: 'container_repositories'
        },
        {
          data_type: 'repository',
          data_type_title: _('Git'),
          title: _('Design repository'),
          title_plural: _('Design repositories'),
          name: 'design_repository',
          name_plural: 'design_repositories',
          secondary_view: true
        }
      ]

      if ::Geo::JobArtifactReplicator.disabled?
        replicable_types.insert(2, {
          data_type: 'blob',
          data_type_title: _('File'),
          title: _('Job artifact'),
          title_plural: _('Job artifacts'),
          name: 'job_artifact',
          name_plural: 'job_artifacts'
        })
      end

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
            secondary_view: true
          }
        )
      end

      replicable_types
    end

    def enabled_replicator_classes
      ::Gitlab::Geo.enabled_replicator_classes
    end
  end
end
