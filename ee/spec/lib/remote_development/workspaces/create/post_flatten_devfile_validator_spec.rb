# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::RemoteDevelopment::Workspaces::Create::PostFlattenDevfileValidator, feature_category: :remote_development do
  include ResultMatchers

  include_context 'with remote development shared fixtures'

  let(:flattened_devfile_name) { 'example.flattened-with-entries-devfile.yaml' }
  let(:processed_devfile) { YAML.safe_load(read_devfile(flattened_devfile_name)) }
  let(:value) { { processed_devfile: processed_devfile } }

  subject(:result) do
    described_class.validate(value)
  end

  context 'for devfiles containing no violations' do
    it 'returns an ok Result containing the original value' do
      expect(result).to eq(Result.ok({ processed_devfile: processed_devfile }))
    end

    context 'when devfile has multiple array entries' do
      let(:flattened_devfile_name) { 'example.multi-entry-devfile.yaml' }

      it 'returns an ok Result containing the original value' do
        expect(result).to eq(Result.ok({ processed_devfile: processed_devfile }))
      end
    end
  end

  context 'for devfiles containing post flatten violations' do
    using RSpec::Parameterized::TableSyntax

    # rubocop:disable Layout/LineLength
    where(:flattened_devfile_name, :error_str) do
      'example.invalid-restricted-prefix-command-apply-component-name-devfile.yaml' | "Component name 'gl-example' for command id 'example' must not start with 'gl-'"
      'example.invalid-restricted-prefix-command-exec-component-name-devfile.yaml' | "Component name 'gl-example' for command id 'example' must not start with 'gl-'"
      'example.invalid-restricted-prefix-command-name-devfile.yaml' | "Command id 'gl-example' must not start with 'gl-'"
      'example.invalid-restricted-prefix-component-container-endpoint-name-devfile.yaml' | "Endpoint name 'gl-example' of component 'example' must not start with 'gl-'"
      'example.invalid-restricted-prefix-component-name-devfile.yaml' | "Component name 'gl-example' must not start with 'gl-'"
      'example.invalid-restricted-prefix-event-type-prestart-name-devfile.yaml' | "Event 'gl-example' of type 'preStart' must not start with 'gl-'"
      'example.invalid-restricted-prefix-variable-name-devfile.yaml' | "Variable name 'gl-example' must not start with 'gl-'"
      'example.invalid-restricted-prefix-variable-name-with-underscore-devfile.yaml' | "Variable name 'gl_example' must not start with 'gl_'"
      'example.invalid-unsupported-component-type-image-devfile.yaml' | "Component type 'image' is not yet supported"
      'example.invalid-unsupported-component-type-kubernetes-devfile.yaml' | "Component type 'kubernetes' is not yet supported"
      'example.invalid-unsupported-component-type-openshift-devfile.yaml' | "Component type 'openshift' is not yet supported"
      'example.invalid-components-entry-empty-devfile.yaml' | "No components present in devfile"
      'example.invalid-components-entry-missing-devfile.yaml' | "No components present in devfile"
      'example.invalid-component-missing-name.yaml' | "Components must have a 'name'"
      'example.invalid-attributes-editor-injector-absent-devfile.yaml' | "No component has 'gl/inject-editor' attribute"
      'example.invalid-attributes-editor-injector-multiple-devfile.yaml' | "Multiple components '[\"tooling-container\", \"tooling-container-2\"]' have 'gl/inject-editor' attribute"
      'example.invalid-unsupported-component-container-dedicated-pod-devfile.yaml' | "Property 'dedicatedPod' of component 'example' is not yet supported"
      'example.invalid-unsupported-starter-projects-devfile.yaml' | "'starterProjects' is not yet supported"
      'example.invalid-unsupported-projects-devfile.yaml' | "'projects' is not yet supported"
      'example.invalid-unsupported-event-type-poststart-devfile.yaml' | "Event type 'postStart' is not yet supported"
      'example.invalid-unsupported-event-type-prestop-devfile.yaml' | "Event type 'preStop' is not yet supported"
      'example.invalid-unsupported-event-type-poststop-devfile.yaml' | "Event type 'postStop' is not yet supported"
    end
    # rubocop:enable Layout/LineLength

    with_them do
      it 'returns an err Result containing error details' do
        is_expected.to be_err_result do |message|
          expect(message).to be_a(RemoteDevelopment::Messages::WorkspaceCreatePostFlattenDevfileValidationFailed)
          message.context => { details: String => error_details }
          # noinspection RubyResolve
          expect(error_details).to eq(error_str)
        end
      end
    end
  end

  context 'for multi-array-entry devfiles containing post flatten violations' do
    # NOTE: This context guards against the incorrect usage of
    #       `return Result.ok(value) unless condition`
    #       guard clauses within iterator blocks in the validator logic.
    #       Because the behavior of `return` in Ruby is to return from the entire containing method,
    #       regardless of how many blocks you are nexted within, this would result in early returns
    #       which do not process all entries which are being iterated over.

    using RSpec::Parameterized::TableSyntax

    # rubocop:disable Layout/LineLength
    where(:flattened_devfile_name, :error_str) do
      'example.invalid-multi-component-devfile.yaml' | "Component name 'gl-example-invalid-second-component' must not start with 'gl-'"
      'example.invalid-multi-endpoint-devfile.yaml' | "Endpoint name 'gl-example-invalid-second-endpoint' of component 'example-invalid-second-component' must not start with 'gl-'"
      'example.invalid-multi-command-devfile.yaml' | "Component name 'gl-example-invalid-component' for command id 'example-invalid-second-component-command' must not start with 'gl-'"
      'example.invalid-multi-event-devfile.yaml' | "Event 'gl-example' of type 'preStart' must not start with 'gl-'"
      'example.invalid-multi-variable-devfile.yaml' | "Variable name 'gl-example-invalid' must not start with 'gl-'"
    end
    # rubocop:enable Layout/LineLength

    with_them do
      it 'returns an err Result containing error details' do
        is_expected.to be_err_result do |message|
          expect(message).to be_a(RemoteDevelopment::Messages::WorkspaceCreatePostFlattenDevfileValidationFailed)
          message.context => { details: String => error_details }
          # noinspection RubyResolve
          expect(error_details).to eq(error_str)
        end
      end
    end
  end
end
