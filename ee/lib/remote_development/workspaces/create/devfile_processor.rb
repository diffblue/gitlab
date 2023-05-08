# frozen_string_literal: true

require 'devfile'

module RemoteDevelopment
  module Workspaces
    module Create
      class DevfileProcessor
        WORKSPACE_VOLUME = 'gl-workspace-data'

        def process(devfile:, editor:, project:, workspace_root:)
          flattened_devfile_yaml = Devfile::Parser.flatten(devfile)
          flattened_devfile = YAML.safe_load(flattened_devfile_yaml)
          DevfileValidator.new.validate(flattened_devfile: flattened_devfile)

          flattened_devfile = add_workspace_volume(flattened_devfile: flattened_devfile, volume_name: WORKSPACE_VOLUME)
          flattened_devfile = add_editor(
            flattened_devfile: flattened_devfile,
            editor: editor,
            volume_reference: WORKSPACE_VOLUME,
            volume_mount_dir: workspace_root
          )
          flattened_devfile = add_project_cloner(
            flattened_devfile: flattened_devfile,
            project: project,
            volume_reference: WORKSPACE_VOLUME,
            volume_mount_dir: workspace_root
          )

          YAML.dump(flattened_devfile)
        end

        private

        # noinspection RubyUnusedLocalVariable
        # rubocop:disable Lint/UnusedMethodArgument
        def add_editor(flattened_devfile:, editor:, volume_reference:, volume_mount_dir:)
          editor_port = 60001
          # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409775 - choose image based on which editor is passed.
          image_name = 'registry.gitlab.com/gitlab-org/gitlab-web-ide-vscode-fork/web-ide-injector'
          image_tag = '1'
          editor_components = [
            {
              'name' => 'gl-editor-injector',
              'container' => {
                'image' => "#{image_name}:#{image_tag}",
                'volumeMounts' => [{ 'name' => volume_reference, 'path' => volume_mount_dir }],
                'env' => [
                  {
                    'name' => 'EDITOR_VOLUME_DIR',
                    'value' => "#{volume_mount_dir}/.gl-editor"
                  },
                  {
                    'name' => 'EDITOR_PORT',
                    'value' => editor_port.to_s
                  }
                ],
                'memoryLimit' => '128Mi',
                'memoryRequest' => '32Mi',
                'cpuLimit' => '500m',
                'cpuRequest' => '30m'
              }
            }
          ]

          editor_component_found = false
          flattened_devfile['components'].map do |component|
            next unless component.dig('attributes', 'gl/inject-editor')
            next if editor_component_found

            editor_component_found = true
            # This overrides the main container's command
            # Open issue to support both starting the editor and running the default command:
            # https://gitlab.com/gitlab-org/gitlab/-/issues/392853
            component['container']['command'] = ["#{volume_mount_dir}/.gl-editor/start_server.sh"]

            component['container']['volumeMounts'] = [] if component['container']['volumeMounts'].nil?

            component['container']['volumeMounts'] += [{ 'name' => volume_reference, 'path' => volume_mount_dir }]

            component['container']['env'] = [] if component['container']['env'].nil?

            component['container']['env'] += [
              {
                'name' => 'EDITOR_VOLUME_DIR',
                'value' => "#{volume_mount_dir}/.gl-editor"
              },
              {
                'name' => 'EDITOR_PORT',
                'value' => editor_port.to_s
              }
            ]

            component['container']['endpoints'] = [] if component['container']['endpoints'].nil?

            component['container']['endpoints'].append(
              {
                'name' => 'editor-server',
                'targetPort' => editor_port,
                'exposure' => 'public',
                'secure' => true,
                'protocol' => 'https'
              }
            )

            component
          end

          # TODO: figure out what to do when no editor injection component is found
          if editor_component_found
            flattened_devfile['components'] += editor_components

            flattened_devfile['commands'] = [] if flattened_devfile['commands'].nil?

            flattened_devfile['commands'] += [{
              'id' => 'gl-editor-injector-command',
              'apply' => {
                'component' => 'gl-editor-injector'
              }
            }]

            flattened_devfile['events'] = {} if flattened_devfile['events'].nil?

            flattened_devfile['events']['preStart'] = [] if flattened_devfile['events']['preStart'].nil?

            flattened_devfile['events']['preStart'] += ['gl-editor-injector-command']
          end

          flattened_devfile
        end
        # rubocop:enable Lint/UnusedMethodArgument

        def add_project_cloner(flattened_devfile:, project:, volume_reference:, volume_mount_dir:)
          # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/408448
          #       replace the alpine/git docker image with one that is published by gitlab for security / reliability
          #       reasons
          image_name = 'alpine/git'
          image_tag = '2.36.3'

          clone_dir = "#{volume_mount_dir}/#{project.path}"

          # project is cloned only if one doesn't exist already
          # this done to avoid resetting user's modifications to the workspace
          project_url = project.http_url_to_repo
          project_ref = project.default_branch
          container_args = <<~SH.chomp
            if [ ! -d '#{clone_dir}' ];
            then
              git clone --branch #{Shellwords.shellescape(project_ref)} #{Shellwords.shellescape(project_url)} #{Shellwords.shellescape(clone_dir)};
            fi
          SH

          # TODO: https://gitlab.com/groups/gitlab-org/-/epics/10461
          #       implement better error handling to allow cloner to be able to deal with different categories of errors
          # issue: https://gitlab.com/gitlab-org/gitlab/-/issues/408451
          cloner_component = {
            'name' => 'gl-cloner-injector',
            'container' => {
              'image' => "#{image_name}:#{image_tag}",
              'volumeMounts' => [{ 'name' => volume_reference, 'path' => volume_mount_dir }],
              'args' => [container_args],
              # command has been overridden here as the default command in the alpine/git
              # container invokes git directly
              'command' => %w[/bin/sh -c],
              'memoryLimit' => '128Mi',
              'memoryRequest' => '32Mi',
              'cpuLimit' => '500m',
              'cpuRequest' => '30m'
            }
          }

          flattened_devfile['components'] ||= []
          flattened_devfile['components'] << cloner_component

          # create a command that will invoke the cloner
          cloner_command = {
            'id' => 'gl-cloner-injector-command',
            'apply' => {
              'component' => cloner_component['name']
            }
          }
          flattened_devfile['commands'] ||= []
          flattened_devfile['commands'] << cloner_command

          # configure the workspace to run the cloner command upon workspace start
          flattened_devfile['events'] ||= {}
          flattened_devfile['events']['preStart'] ||= []
          flattened_devfile['events']['preStart'] << cloner_command['id']

          flattened_devfile
        end

        def add_workspace_volume(flattened_devfile:, volume_name:)
          component = {
            'name' => volume_name,
            'volume' => {
              'size' => '15Gi'
            }
          }

          flattened_devfile['components'] ||= []
          flattened_devfile['components'] << component

          flattened_devfile
        end
      end
    end
  end
end
