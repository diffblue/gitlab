# frozen_string_literal: true

module SystemCheck
  module Geo
    class SshPortCheck < SystemCheck::BaseCheck
      set_name 'GitLab Geo secondary Git SSH port is the same as the primary'
      set_skip_reason 'not a secondary site with Git over SSH enabled (Admin > Settings)'

      def skip?
        !Gitlab::Geo.secondary? || !ssh_git_protocol_enabled?
      end

      def check?
        configured_ssh_port == primary_ssh_port
      end

      def show_error
        try_fixing_it(
          "This site's Git SSH port is: #{configured_ssh_port}, " \
          "but the primary site's Git SSH port is: #{primary_ssh_port}.",
          "Update this site's SSH port to match the primary's SSH port:",
          "- Omnibus GitLab: Update gitlab_rails['gitlab_shell_ssh_port'] in /etc/gitlab/gitlab.rb",
          "- GitLab Charts: See https://docs.gitlab.com/charts/charts/globals#port",
          "- GitLab Development Kit: See https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/" \
          "ssh.md#change-the-listen-port-or-other-configuration"
        )

        for_more_information('doc/administration/geo/index.md#limitations')
      end

      private

      def enabled_git_access_protocol
        Gitlab::CurrentSettings.current_application_settings.enabled_git_access_protocol
      end

      def ssh_git_protocol_enabled?
        enabled_git_access_protocol.blank? || enabled_git_access_protocol == 'ssh'
      end

      def configured_ssh_port
        Gitlab.config.gitlab_shell.ssh_port
      end

      def primary_ssh_port
        primary_ssh_url = GeoNode.primary_node.clone_url_prefix

        if primary_ssh_url.start_with? %r{\Assh://}
          URI.parse(primary_ssh_url).port
        else
          # clone_url_prefix does not have a port if gitlab_shell.ssh_port is set to 22
          22
        end
      end
    end
  end
end
