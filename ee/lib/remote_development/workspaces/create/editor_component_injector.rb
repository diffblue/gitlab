# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Create
      class EditorComponentInjector
        include Messages

        # @param [Hash] value
        # @return [Hash]
        def self.inject(value)
          value => {
            processed_devfile: Hash => processed_devfile,
            volume_mounts: Hash => volume_mounts,
            # params: Hash => params # NOTE: Params is currently unused until we use the editor entry
          }
          volume_mounts => { data_volume: Hash => data_volume }
          data_volume => {
            name: String => volume_name,
            path: String => volume_path,
          }

          # NOTE: Editor is currently unused
          # editor = params[:editor]

          editor_port = 60001
          ssh_port = 60022

          # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409775 - choose image based on which editor is passed.
          image_name = 'registry.gitlab.com/gitlab-org/gitlab-web-ide-vscode-fork/web-ide-injector'
          image_tag = '2'
          editor_components = [
            {
              'name' => 'gl-editor-injector',
              'container' => {
                'image' => "#{image_name}:#{image_tag}",
                'volumeMounts' => [{ 'name' => volume_name, 'path' => volume_path }],
                'env' => [
                  {
                    'name' => 'EDITOR_VOLUME_DIR',
                    'value' => "#{volume_path}/.gl-editor"
                  },
                  {
                    'name' => 'EDITOR_PORT',
                    'value' => editor_port.to_s
                  },
                  {
                    'name' => 'SSH_PORT',
                    'value' => ssh_port.to_s
                  }
                ],
                'memoryLimit' => '256Mi',
                'memoryRequest' => '128Mi',
                'cpuLimit' => '500m',
                'cpuRequest' => '100m'
              }
            }
          ]

          editor_component_found = false
          processed_devfile['components'].map do |component|
            next unless component.dig('attributes', 'gl/inject-editor')
            next if editor_component_found

            editor_component_found = true
            # This overrides the main container's command
            # Open issue to support both starting the editor and running the default command:
            # https://gitlab.com/gitlab-org/gitlab/-/issues/392853
            component['container']['command'] = ["#{volume_path}/.gl-editor/start_server.sh"]

            component['container']['volumeMounts'] = [] if component['container']['volumeMounts'].nil?

            component['container']['volumeMounts'] += [{ 'name' => volume_name, 'path' => volume_path }]

            component['container']['env'] = [] if component['container']['env'].nil?

            component['container']['env'] += [
              {
                'name' => 'EDITOR_VOLUME_DIR',
                'value' => "#{volume_path}/.gl-editor"
              },
              {
                'name' => 'EDITOR_PORT',
                'value' => editor_port.to_s
              },
              {
                'name' => 'SSH_PORT',
                'value' => ssh_port.to_s
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
              },
              {
                'name' => 'ssh-server',
                'targetPort' => ssh_port,
                'exposure' => 'internal',
                'secure' => true
              }
            )

            component
          end

          # TODO: figure out what to do when no editor injection component is found
          if editor_component_found
            processed_devfile['components'] += editor_components

            processed_devfile['commands'] = [] if processed_devfile['commands'].nil?

            processed_devfile['commands'] += [{
              'id' => 'gl-editor-injector-command',
              'apply' => {
                'component' => 'gl-editor-injector'
              }
            }]

            processed_devfile['events'] = {} if processed_devfile['events'].nil?

            processed_devfile['events']['preStart'] = [] if processed_devfile['events']['preStart'].nil?

            processed_devfile['events']['preStart'] += ['gl-editor-injector-command']
          end

          value
        end
      end
    end
  end
end
