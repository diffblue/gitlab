# frozen_string_literal: true

module EE
  module GitlabRoutingHelper
    def geo_primary_web_url(container, internal: false)
      primary_base_url = if internal
                           ::Gitlab::Geo.primary_node_internal_url
                         else
                           ::Gitlab::Geo.primary_node_url
                         end

      File.join(primary_base_url, container.full_path)
    end

    def geo_primary_ssh_url_to_repo(container)
      "#{::Gitlab::Geo.primary_node.clone_url_prefix}#{container.full_path}.git"
    end

    def geo_primary_http_url_to_repo(container)
      geo_primary_web_url(container) + '.git'
    end

    def geo_proxied_http_url_to_repo(proxied_site, container)
      "#{File.join(proxied_site.url, container.full_path)}.git"
    end

    def geo_proxied_ssh_url_to_repo(proxied_site, container)
      primary_ssh_url = container.ssh_url_to_repo

      if ::Gitlab.config.gitlab_shell.ssh_host != Settings.gitlab.host
        primary_ssh_url
      else
        secondary_host = proxied_site.uri.host

        # Note: if ssh_port is configured to 22, resulting ssh url does not contain the port
        # URI.parse does not parse urls with no port
        # Substitute original ssh_host with the proxied site host
        primary_ssh_url.gsub(::Gitlab.config.gitlab_shell.ssh_host, secondary_host)
      end
    end

    def geo_primary_http_internal_url_to_repo(container)
      geo_primary_web_url(container, internal: true) + '.git'
    end

    def geo_primary_default_url_to_repo(container)
      case default_clone_protocol
      when 'ssh'
        geo_primary_ssh_url_to_repo(container)
      else
        geo_primary_http_url_to_repo(container)
      end
    end

    def license_management_api_url(project)
      expose_path(api_v4_projects_managed_licenses_path(id: project.id))
    end

    def license_management_settings_path(project)
      project_licenses_path(project, anchor: 'policies')
    end

    def vulnerability_path(entity, *args)
      project_security_vulnerability_path(entity.project, entity, *args)
    end

    def vulnerability_url(vulnerability)
      ::Gitlab::UrlBuilder.build(vulnerability)
    end

    def project_vulnerability_path(project, vulnerability, *args)
      project_security_vulnerability_path(project, vulnerability, *args)
    end

    def upgrade_plan_path(group)
      return profile_billings_path if group.blank?

      group_billings_path(group)
    end

    def self.url_helper(route_name)
      define_method("#{route_name}_url") do |*args|
        path = public_send(:"#{route_name}_path", *args) # rubocop:disable GitlabSecurity/PublicSend
        options = Rails.application.routes.default_url_options.merge(path: path)
        ActionDispatch::Http::URL.full_url_for(options)
      end
    end

    url_helper :epic
    def epic_path(entity, *args)
      group_epic_path(entity.group, entity, *args)
    end

    url_helper :user_group_saml_omniauth_metadata
    def user_group_saml_omniauth_metadata_path(group)
      params = { group_path: group.path, token: group.saml_discovery_token }
      path = '/users/auth/group_saml/metadata'

      ActionDispatch::Http::URL.path_for(path: path, params: params)
    end

    def usage_quotas_path(namespace, *args)
      if namespace.group_namespace?
        group_usage_quotas_path(namespace, *args)
      else
        profile_usage_quotas_path(*args)
      end
    end

    def usage_quotas_url(namespace, *args)
      if namespace.group_namespace?
        group_usage_quotas_url(namespace, *args)
      else
        profile_usage_quotas_url(*args)
      end
    end
  end
end
