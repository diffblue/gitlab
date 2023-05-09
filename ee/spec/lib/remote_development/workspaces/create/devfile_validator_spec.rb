# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::Workspaces::Create::DevfileValidator, feature_category: :remote_development do
  include_context 'with remote development shared fixtures'

  let(:devfile_name) { 'example.devfile.yaml' }
  let(:devfile) { YAML.safe_load(read_devfile(devfile_name)) }

  describe '#validate' do
    subject do
      described_class.new
    end

    context 'for devfiles containing no violations' do
      # noinspection RubyResolve
      it 'does not raises an error' do
        expect { subject.post_flatten_validate(flattened_devfile: devfile) }.not_to raise_error
      end
    end

    context 'for devfiles containing post flatten violations' do
      using RSpec::Parameterized::TableSyntax

      # rubocop:disable Layout/LineLength
      where(:devfile_name, :error_str) do
        'example.invalid-restricted-prefix-command-apply-component-name-devfile.yaml'      | "Component name 'gl-example' for command id 'example' starts with 'gl-'"
        'example.invalid-restricted-prefix-command-exec-component-name-devfile.yaml'       | "Component name 'gl-example' for command id 'example' starts with 'gl-'"
        'example.invalid-restricted-prefix-command-name-devfile.yaml'                      | "Command id 'gl-example' starts with 'gl-'"
        'example.invalid-restricted-prefix-component-container-endpoint-name-devfile.yaml' | "Endpoint name 'gl-example' of component 'example' starts with 'gl-'"
        'example.invalid-restricted-prefix-component-name-devfile.yaml'                    | "Component name 'gl-example' starts with 'gl-'"
        'example.invalid-restricted-prefix-event-type-prestart-name-devfile.yaml'          | "Event 'gl-example' of type 'preStart' starts with 'gl-'"
        'example.invalid-restricted-prefix-variable-name-devfile.yaml'                     | "Variable name 'gl-example' starts with 'gl-'"
        'example.invalid-restricted-prefix-variable-name-with-underscore-devfile.yaml'     | "Variable name 'gl_example' starts with 'gl_'"
        'example.invalid-unsupported-component-type-image-devfile.yaml'                    | "Component type 'image' is not yet supported"
        'example.invalid-unsupported-component-type-kubernetes-devfile.yaml'               | "Component type 'kubernetes' is not yet supported"
        'example.invalid-unsupported-component-type-openshift-devfile.yaml'                | "Component type 'openshift' is not yet supported"
        'example.invalid-no-components-devfile.yaml'                                       | "No components present in the devfile"
        'example.invalid-attributes-editor-injector-absent-devfile.yaml'                   | "No component has 'gl/inject-editor' attribute"
        'example.invalid-attributes-editor-injector-multiple-devfile.yaml'                 | "Multiple components([\"tooling-container\", \"tooling-container-2\"]) have 'gl/inject-editor' attribute"
        'example.invalid-unsupported-component-container-dedicated-pod-devfile.yaml'       | "Property 'dedicatedPod' of component 'example' is not yet supported"
        'example.invalid-unsupported-starter-projects-devfile.yaml'                        | "'starterProjects' is not yet supported"
        'example.invalid-unsupported-projects-devfile.yaml'                                | "'projects' is not yet supported"
        'example.invalid-unsupported-event-type-poststart-devfile.yaml'                    | "Event type 'postStart' is not yet supported"
        'example.invalid-unsupported-event-type-prestop-devfile.yaml'                      | "Event type 'preStop' is not yet supported"
        'example.invalid-unsupported-event-type-poststop-devfile.yaml'                     | "Event type 'postStop' is not yet supported"
      end
      # rubocop:enable Layout/LineLength
      with_them do
        # noinspection RubyResolve
        it 'raises an error' do
          expect { subject.post_flatten_validate(flattened_devfile: devfile) }.to raise_error(ArgumentError, error_str)
        end
      end
    end

    context 'for devfiles containing pre flatten violations' do
      using RSpec::Parameterized::TableSyntax

      where(:devfile_name, :error_str) do
        'example.invalid-unsupported-parent-inheritance-devfile.yaml' | "Inheriting from 'parent' is not yet supported"
      end
      with_them do
        it 'raises an error' do
          expect { subject.pre_flatten_validate(devfile: devfile) }.to raise_error(ArgumentError, error_str)
        end
      end
    end
  end
end
