# frozen_string_literal: true

require_relative '../../fast_spec_helper'

RSpec.describe RemoteDevelopment::Workspaces::Create::Main, feature_category: :remote_development do
  include RemoteDevelopment::RailwayOrientedProgrammingHelpers

  let(:value) { {} }
  let(:error_details) { 'some error details' }
  let(:err_message_context) { { details: error_details } }

  # rubocop:disable Layout/LineLength - keep all the class and method fixtures as single-liners easier scanning/editing
  # Classes

  let(:authorizer_class) { RemoteDevelopment::Workspaces::Create::Authorizer }
  let(:devfile_fetcher_class) { RemoteDevelopment::Workspaces::Create::DevfileFetcher }
  let(:pre_flatten_devfile_validator_class) { RemoteDevelopment::Workspaces::Create::PreFlattenDevfileValidator }
  let(:devfile_flattener_class) { RemoteDevelopment::Workspaces::Create::DevfileFlattener }
  let(:post_flatten_devfile_validator_class) { RemoteDevelopment::Workspaces::Create::PostFlattenDevfileValidator }
  let(:volume_definer_class) { RemoteDevelopment::Workspaces::Create::VolumeDefiner }
  let(:volume_component_injector_class) { RemoteDevelopment::Workspaces::Create::VolumeComponentInjector }
  let(:editor_component_injector_class) { RemoteDevelopment::Workspaces::Create::EditorComponentInjector }
  let(:project_cloner_component_injector_class) { RemoteDevelopment::Workspaces::Create::ProjectClonerComponentInjector }
  let(:creator_class) { RemoteDevelopment::Workspaces::Create::Creator }

  # Methods

  let(:authorizer_method) { authorizer_class.singleton_method(:authorize) }
  let(:devfile_fetcher_method) { devfile_fetcher_class.singleton_method(:fetch) }
  let(:pre_flatten_devfile_validator_method) { pre_flatten_devfile_validator_class.singleton_method(:validate) }
  let(:devfile_flattener_method) { devfile_flattener_class.singleton_method(:flatten) }
  let(:post_flatten_devfile_validator_method) { post_flatten_devfile_validator_class.singleton_method(:validate) }
  let(:volume_definer_method) { volume_definer_class.singleton_method(:define) }
  let(:volume_component_injector_method) { volume_component_injector_class.singleton_method(:inject) }
  let(:editor_component_injector_method) { editor_component_injector_class.singleton_method(:inject) }
  let(:project_cloner_component_injector_method) { project_cloner_component_injector_class.singleton_method(:inject) }
  let(:creator_method) { creator_class.singleton_method(:create) }
  # rubocop:enable Layout/LineLength

  # Subject

  subject(:response) { described_class.main(value) }

  before do
    allow(authorizer_class).to receive(:method) { authorizer_method }
    allow(devfile_fetcher_class).to(receive(:method)) { devfile_fetcher_method }
    allow(pre_flatten_devfile_validator_class).to(receive(:method)) { pre_flatten_devfile_validator_method }
    allow(devfile_flattener_class).to receive(:method) { devfile_flattener_method }
    allow(post_flatten_devfile_validator_class).to(receive(:method)) { post_flatten_devfile_validator_method }
    allow(volume_definer_class).to(receive(:method)) { volume_definer_method }
    allow(volume_component_injector_class).to(receive(:method)) { volume_component_injector_method }
    allow(editor_component_injector_class).to(receive(:method)) { editor_component_injector_method }
    allow(project_cloner_component_injector_class).to(receive(:method)) { project_cloner_component_injector_method }
    allow(creator_class).to receive(:method) { creator_method }
  end

  context 'when the Authorizer returns an err Result' do
    before do
      allow(authorizer_method).to receive(:call).with(value) do
        Result.err(RemoteDevelopment::Messages::Unauthorized.new)
      end
    end

    it 'returns an unauthorized error response' do
      expect(response).to eq({ status: :error, message: 'Unauthorized', reason: :unauthorized })
    end
  end

  context 'when the DevfileFetcher returns an err Result' do
    before do
      stub_methods_to_return_ok_result(
        authorizer_method
      )
      stub_methods_to_return_err_result(
        method: devfile_fetcher_method,
        message_class: RemoteDevelopment::Messages::WorkspaceCreateParamsValidationFailed
      )
    end

    it 'returns an error response' do
      expect(response).to eq({
        status: :error,
        message: "Workspace create params validation failed: #{error_details}",
        reason: :bad_request
      })
    end
  end

  context 'when the PreFlattenDevfileValidator returns an err Result' do
    before do
      stub_methods_to_return_ok_result(
        authorizer_method,
        devfile_fetcher_method
      )
      stub_methods_to_return_err_result(
        method: pre_flatten_devfile_validator_method,
        message_class: RemoteDevelopment::Messages::WorkspaceCreatePreFlattenDevfileValidationFailed
      )
    end

    it 'returns an error response' do
      expect(response).to eq({
        status: :error,
        message: "Workspace create pre flatten devfile validation failed: #{error_details}",
        reason: :bad_request
      })
    end
  end

  context 'when the DevfileFlattener returns an err Result' do
    before do
      stub_methods_to_return_ok_result(
        authorizer_method,
        devfile_fetcher_method,
        pre_flatten_devfile_validator_method
      )
      stub_methods_to_return_err_result(
        method: devfile_fetcher_method,
        message_class: RemoteDevelopment::Messages::WorkspaceCreateDevfileFlattenFailed
      )
    end

    it 'returns an error response' do
      expect(response).to eq({
        status: :error,
        message: "Workspace create devfile flatten failed: #{error_details}",
        reason: :bad_request
      })
    end
  end

  context 'when the PostFlattenDevfileValidator returns an err Result' do
    before do
      stub_methods_to_return_ok_result(
        authorizer_method,
        devfile_fetcher_method,
        pre_flatten_devfile_validator_method
      )
      stub_methods_to_return_value(
        devfile_flattener_method
      )
      stub_methods_to_return_err_result(
        method: post_flatten_devfile_validator_method,
        message_class: RemoteDevelopment::Messages::WorkspaceCreatePostFlattenDevfileValidationFailed
      )
    end

    it 'returns an error response' do
      expect(response).to eq({
        status: :error,
        message: "Workspace create post flatten devfile validation failed: #{error_details}",
        reason: :bad_request
      })
    end
  end

  context 'when the Creator returns an err Result' do
    let(:errors) { ActiveModel::Errors.new(:base) }
    let(:err_message_context) { { errors: errors } }

    before do
      stub_methods_to_return_ok_result(
        authorizer_method,
        devfile_fetcher_method,
        pre_flatten_devfile_validator_method,
        devfile_flattener_method,
        post_flatten_devfile_validator_method
      )
      stub_methods_to_return_value(
        devfile_flattener_method,
        volume_definer_method,
        volume_component_injector_method,
        editor_component_injector_method,
        project_cloner_component_injector_method
      )
      stub_methods_to_return_err_result(
        method: creator_method,
        message_class: RemoteDevelopment::Messages::WorkspaceCreateFailed
      )

      errors.add(:base, 'err1')
      errors.add(:base, 'err2')
    end

    it 'returns a workspace create failed error response' do
      expect(response).to eq({
        status: :error,
        message: "Workspace create failed: err1, err2",
        reason: :bad_request
      })
    end
  end

  context 'when the Creator returns an ok Result' do
    let(:workspace) { instance_double("RemoteDevelopment::Workspace") }

    before do
      stub_methods_to_return_ok_result(
        authorizer_method,
        devfile_fetcher_method,
        pre_flatten_devfile_validator_method,
        devfile_flattener_method,
        post_flatten_devfile_validator_method
      )
      stub_methods_to_return_value(
        devfile_flattener_method,
        volume_definer_method,
        volume_component_injector_method,
        editor_component_injector_method,
        project_cloner_component_injector_method
      )
      allow(creator_method).to receive(:call).with(value) do
        Result.ok(RemoteDevelopment::Messages::WorkspaceCreateSuccessful.new({ workspace: workspace }))
      end
    end

    it 'returns a workspace create success response with the workspace as the payload' do
      expect(response).to eq({
        status: :success,
        payload: { workspace: workspace }
      })
    end
  end

  context 'when an invalid Result is returned' do
    let(:workspace) { build_stubbed(:workspace) }

    before do
      stub_methods_to_return_ok_result(
        authorizer_method,
        devfile_fetcher_method,
        pre_flatten_devfile_validator_method,
        devfile_flattener_method,
        post_flatten_devfile_validator_method
      )
      stub_methods_to_return_value(
        devfile_flattener_method,
        volume_definer_method,
        volume_component_injector_method,
        editor_component_injector_method,
        project_cloner_component_injector_method
      )
      allow(creator_method).to receive(:call).with(value) do
        Result.err(RemoteDevelopment::Messages::WorkspaceCreateSuccessful.new)
      end
    end

    it 'raises an UnmatchedResultError' do
      expect { response }.to raise_error(RemoteDevelopment::UnmatchedResultError)
    end
  end
end
