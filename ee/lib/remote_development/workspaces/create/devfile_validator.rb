# frozen_string_literal: true

require 'devfile'

module RemoteDevelopment
  module Workspaces
    module Create
      class DevfileValidator
        # Since this is called after flattening the devfile, we can safely assume that it has valid syntax
        # as per devfile standard. If you are validating something that is not available across all devfile versions,
        # add additional guard clauses.
        # Devfile standard only allows name/id to be of the format /'^[a-z0-9]([-a-z0-9]*[a-z0-9])?$'/
        # Hence, we do no need to restrict the prefix `gl_`.
        # However, we do that for the 'variables' in the flattened_devfile since they do not have any such restriction
        RESTRICTED_PREFIX = 'gl-'

        # Currently, we only support 'container' and 'volume' type components.
        # For container components, ensure no endpoint name starts with restricted_prefix
        UNSUPPORTED_COMPONENT_TYPES = %w[kubernetes openshift image].freeze

        # Currently, we only support 'exec' and 'apply' for validation
        SUPPORTED_COMMAND_TYPES = %w[exec apply].freeze

        # Currently, we only support `preStart` events
        SUPPORTED_EVENTS = %w[preStart].freeze

        # We must ensure that devfiles are not created with a schema version different than the required version
        REQUIRED_DEVFILE_SCHEMA_VERSION = '2.2.0'

        # @param [Hash] devfile
        # @return [void]
        def pre_flatten_validate(devfile:)
          validate_schema_version(devfile: devfile)
          validate_parent(devfile: devfile)
        end

        # @param [Hash] flattened_devfile
        # @return [void]
        def post_flatten_validate(flattened_devfile:)
          validate_projects(flattened_devfile: flattened_devfile)
          validate_components(
            flattened_devfile: flattened_devfile
          )
          validate_commands(
            flattened_devfile: flattened_devfile
          )
          validate_events(flattened_devfile: flattened_devfile)
          validate_variables(flattened_devfile: flattened_devfile)
        end

        private

        # @param [Hash] devfile
        # @return [void]
        def validate_schema_version(devfile:)
          minimum_schema_version = Gem::Version.new(REQUIRED_DEVFILE_SCHEMA_VERSION)
          devfile_schema_version_string = devfile.fetch('schemaVersion')
          devfile_schema_version = nil
          begin
            devfile_schema_version = Gem::Version.new(devfile_schema_version_string)
          rescue ArgumentError
            arg_err!(_("Invalid 'schemaVersion' '%s'"), devfile_schema_version_string)
          end
          return if devfile_schema_version == minimum_schema_version

          arg_err!(
            _("'schemaVersion' '%{given_version}' is not supported, it must be '%{required_version}'"),
            given_version: devfile_schema_version_string,
            required_version: REQUIRED_DEVFILE_SCHEMA_VERSION)
        end

        # @param [Hash] devfile
        # @return [void]
        def validate_parent(devfile:)
          arg_err!(_("Inheriting from 'parent' is not yet supported")) if devfile['parent']
        end

        # @param [Hash] flattened_devfile
        # @return [void]
        def validate_projects(flattened_devfile:)
          arg_err!(_("'starterProjects' is not yet supported")) if flattened_devfile['starterProjects']

          arg_err!(_("'projects' is not yet supported")) if flattened_devfile['projects']
        end

        # @param [Hash] flattened_devfile
        # @return [void]
        def validate_components(flattened_devfile:)
          components = flattened_devfile['components']

          arg_err!(_('No components present in devfile')) if components.nil?

          inject_editor_components = components.select do |component|
            component.dig('attributes', 'gl/inject-editor')
          end

          arg_err!(_("No component has 'gl/inject-editor' attribute")) if inject_editor_components.empty?

          if inject_editor_components.length > 1
            arg_err!(_("Multiple components(%s) have 'gl/inject-editor' attribute"),
              inject_editor_components.pluck('name')) # rubocop:disable CodeReuse/ActiveRecord - this pluck isn't from ActiveRecord, it's from ActiveSupport
          end

          # NOTE: This noinspection will be removed soon with a refactoring to eliminate arg_err!, and directly return
          #       within the guard clause. For now it is just to get a clean RubyMine "Inspect Code" run for the
          #       Remote Development feature.
          # noinspection RubyNilAnalysis
          arg_err!(_("Components must have a 'name'")) unless components.all? { |component| component['name'].present? }

          # Ensure no component name starts with restricted_prefix
          components.each do |component|
            component_name = component.fetch('name')
            if component_name.downcase.start_with?(RESTRICTED_PREFIX)
              arg_err!(
                _("Component name '%{component}' must not start with '%{prefix}'"),
                component: component_name,
                prefix: RESTRICTED_PREFIX)
            end

            UNSUPPORTED_COMPONENT_TYPES.each do |unsupported_component_type|
              if component[unsupported_component_type]
                arg_err!(_("Component type '%s' is not yet supported"), unsupported_component_type)
              end
            end

            validate_container(component: component)
          end
        end

        # @param [Hash] component
        # @return [void]
        def validate_container(component:)
          container = component['container']
          return unless container

          component_name = component.fetch('name')

          if container['dedicatedPod']
            arg_err!(_("Property 'dedicatedPod' of component '%s' is not yet supported"), component_name)
          end

          validate_endpoints(component_name: component_name, container: container)
        end

        # @param [Hash] component_name
        # @param [Hash] container
        # @return [void]
        def validate_endpoints(component_name:, container:)
          return unless container['endpoints']

          container.fetch('endpoints').map do |endpoint|
            endpoint_name = endpoint['name']
            next unless endpoint_name.downcase.start_with?(RESTRICTED_PREFIX)

            arg_err!(
              _("Endpoint name '%{endpoint}' of component '%{component}' must not start with '%{prefix}'"),
              endpoint: endpoint_name,
              component: component_name,
              prefix: RESTRICTED_PREFIX)
          end
        end

        # @param [Hash] flattened_devfile
        # @return [void]
        def validate_commands(flattened_devfile:)
          commands = flattened_devfile['commands']
          return if commands.nil?

          # Ensure no command name starts with restricted_prefix
          commands.each do |command|
            command_id = command.fetch('id')
            if command_id.downcase.start_with?(RESTRICTED_PREFIX)
              arg_err!(
                _("Command id '%{command}' must not start with '%{prefix}'"),
                command: command_id,
                prefix: RESTRICTED_PREFIX)
            end

            # Ensure no command is referring to a component with restricted_prefix
            SUPPORTED_COMMAND_TYPES.each do |supported_command_type|
              command_type = command[supported_command_type]
              next if command_type.nil?

              component_name = command_type['component']
              next unless component_name.downcase.start_with?(RESTRICTED_PREFIX)

              arg_err!(
                _("Component name '%{component}' for command id '%{command}' must not start with '%{prefix}'"),
                component: component_name,
                command: command_id,
                prefix: RESTRICTED_PREFIX)
            end
          end
        end

        # @param [Hash] flattened_devfile
        # @return [void]
        def validate_events(flattened_devfile:)
          events = flattened_devfile['events']
          return if events.nil?

          events.map do |event_type, event_type_events|
            # Ensure no event type other than "preStart" are allowed

            arg_err!(_("Event type '%s' is not yet supported"), event_type) unless SUPPORTED_EVENTS.include?(event_type)

            # Ensure no event starts with restricted_prefix
            event_type_events.each do |event|
              next unless event.downcase.start_with?(RESTRICTED_PREFIX)

              arg_err!(
                _("Event '%{event}' of type '%{event_type}' must not start with '%{prefix}'"),
                event: event,
                event_type: event_type,
                prefix: RESTRICTED_PREFIX)
            end
          end
        end

        # @param [Hash] flattened_devfile
        # @return [void]
        def validate_variables(flattened_devfile:)
          variables = flattened_devfile['variables']
          return if variables.nil?

          restricted_prefix_underscore = RESTRICTED_PREFIX.tr("-", "_")

          # Ensure no variables name starts with restricted_prefix
          variables.map do |variable, _|
            [RESTRICTED_PREFIX, restricted_prefix_underscore].each do |prefix|
              next unless variable.downcase.start_with?(prefix)

              arg_err!(
                _("Variable name '%{variable}' must not start with '%{prefix}'"),
                variable: variable,
                prefix: prefix)
            end
          end
        end

        # @param [String] msg
        # @param [Object] format_args
        # @return [String]
        # @raise [ArgumentError]
        def arg_err!(msg, *format_args)
          msg = format(msg, *format_args) unless format_args.empty?
          raise ArgumentError, msg
        end
      end
    end
  end
end
