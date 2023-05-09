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

        def pre_flatten_validate(devfile:)
          validate_parent(devfile: devfile)
        end

        def post_flatten_validate(flattened_devfile:)
          validate_projects(flattened_devfile: flattened_devfile)
          validate_components(
            flattened_devfile: flattened_devfile,
            restricted_prefix: RESTRICTED_PREFIX,
            unsupported_component_types: UNSUPPORTED_COMPONENT_TYPES
          )
          validate_commands(
            flattened_devfile: flattened_devfile,
            restricted_prefix: RESTRICTED_PREFIX,
            supported_command_types: SUPPORTED_COMMAND_TYPES
          )
          validate_events(flattened_devfile: flattened_devfile, restricted_prefix: RESTRICTED_PREFIX)
          validate_variables(flattened_devfile: flattened_devfile, restricted_prefix: RESTRICTED_PREFIX)
        end

        private

        def validate_parent(devfile:)
          raise ArgumentError, _("Inheriting from 'parent' is not yet supported") if devfile['parent']
        end

        def validate_projects(flattened_devfile:)
          raise ArgumentError, _("'starterProjects' is not yet supported") if flattened_devfile['starterProjects']

          raise ArgumentError, _("'projects' is not yet supported") if flattened_devfile['projects']
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        def validate_components(flattened_devfile:, restricted_prefix:, unsupported_component_types:)
          components = flattened_devfile['components']

          raise ArgumentError, _('No components present in the devfile') if components.nil?

          inject_editor_components = components.select do |component|
            component.dig('attributes', 'gl/inject-editor')
          end

          raise ArgumentError, _("No component has 'gl/inject-editor' attribute") if inject_editor_components.empty?

          if inject_editor_components.length > 1
            error_str = format(
              "Multiple components(%s) have 'gl/inject-editor' attribute",
              inject_editor_components.pluck('name') # rubocop:disable CodeReuse/ActiveRecord - Oh you silly CodeReuse/ActiveRecord, this pluck isn't even from ActiveRecord, it's from ActiveSupport!!!
            )
            raise ArgumentError, _(error_str)
          end

          # Ensure no component name starts with restricted_prefix
          components.each do |component|
            component_name = component['name']
            if component_name.downcase.start_with?(restricted_prefix)
              error_str = format("Component name '%s' starts with '%s'", component_name, restricted_prefix)
              raise ArgumentError, _(error_str)
            end

            unsupported_component_types.each do |unsupported_component_type|
              unless component[unsupported_component_type].nil?
                error_str = format("Component type '%s' is not yet supported", unsupported_component_type)
                raise ArgumentError, _(error_str)
              end
            end

            container = component['container']
            # Choosing to disable rubocop rule since we might add validations for other component types in the future.
            # Add adding a guard clause now might create a regression later
            # since we have only validate each component type if they are present.
            # rubocop:disable Style/Next
            unless container.nil?
              if container['dedicatedPod']
                error_str = format(
                  "Property 'dedicatedPod' of component '%s' is not yet supported",
                  component_name
                )
                raise ArgumentError, _(error_str)
              end

              next if container['endpoints'].nil?

              container['endpoints'].map do |endpoint|
                endpoint_name = endpoint['name']
                if endpoint_name.downcase.start_with?(restricted_prefix)
                  error_str = format(
                    "Endpoint name '%s' of component '%s' starts with '%s'",
                    endpoint_name, component_name, restricted_prefix
                  )
                  raise ArgumentError, _(error_str)
                end
              end
            end
            # rubocop:enable Style/Next
          end
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        def validate_commands(flattened_devfile:, restricted_prefix:, supported_command_types:)
          commands = flattened_devfile['commands']
          return if commands.nil?

          # Ensure no command name starts with restricted_prefix
          commands.each do |command|
            command_id = command['id']
            if command_id.downcase.start_with?(restricted_prefix)
              error_str = format("Command id '%s' starts with '%s'", command_id, restricted_prefix)
              raise ArgumentError, _(error_str)
            end

            # Ensure no command is referring to a component with restricted_prefix
            supported_command_types.each do |supported_command_type|
              command_type = command[supported_command_type]
              next if command_type.nil?

              component_name = command_type['component']
              next unless component_name.downcase.start_with?(restricted_prefix)

              error_str = format(
                "Component name '%s' for command id '%s' starts with '%s'",
                component_name, command_id, restricted_prefix
              )
              raise ArgumentError, _(error_str)
            end
          end
        end

        def validate_events(flattened_devfile:, restricted_prefix:)
          events = flattened_devfile['events']
          return if events.nil?

          events.map do |event_type, event_type_events|
            # Ensure no event type other than "preStart" are allowed
            unless event_type == 'preStart'
              error_str = format("Event type '%s' is not yet supported", event_type)
              raise ArgumentError, _(error_str)
            end

            # Ensure no event starts with restricted_prefix
            event_type_events.each do |event|
              if event.downcase.start_with?(restricted_prefix)
                error_str = format("Event '%s' of type '%s' starts with '%s'", event, event_type, restricted_prefix)
                raise ArgumentError, _(error_str)
              end
            end
          end
        end

        def validate_variables(flattened_devfile:, restricted_prefix:)
          variables = flattened_devfile['variables']
          return if variables.nil?

          restricted_prefix_underscore = restricted_prefix.tr("-", "_")

          # Ensure no variables name starts with restricted_prefix
          variables.map do |variable, _|
            [restricted_prefix, restricted_prefix_underscore].each do |prefix|
              if variable.downcase.start_with?(prefix)
                error_str = format("Variable name '%s' starts with '%s'", variable, prefix)
                raise ArgumentError, _(error_str)
              end
            end
          end
        end
      end
    end
  end
end
