# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Onboarding::CreateLearnGitlabWorker, type: :worker, feature_category: :onboarding do
  include AfterNextHelpers

  let_it_be(:namespace) { create(:namespace) }

  describe '#perform' do
    let(:template_path) { '_template_path_' }
    let(:project_name) { '_project_name_' }
    let(:user_id) { namespace.owner_id }

    subject(:perform) { described_class.new.perform(template_path, project_name, namespace.id, user_id) }

    context 'when user exists' do
      let(:handle) { double }
      let(:expected_arguments) { { namespace_id: namespace.id, file: handle, name: project_name } }

      before do
        allow(File).to receive(:open).and_call_original
      end

      it 'invokes Projects::GitlabProjectsImportService' do
        expect(File).to receive(:open).with(template_path).and_yield(handle)
        expect_next(::Projects::GitlabProjectsImportService, namespace.owner, expected_arguments)
          .to receive(:execute)

        perform
      end
    end

    context 'when user does not exist' do
      let(:logger) { described_class.new.send(:logger) }
      let(:user_id) { non_existing_record_id }

      it 'logs an error' do
        log_parameters = {
          worker: described_class.name,
          namespace_id: namespace.id,
          user_id: user_id
        }

        expect(logger).to receive(:error).with(a_hash_including(log_parameters))

        perform
      end
    end

    context 'when learn gitlab project already exists' do
      let(:logger) { described_class.new.send(:logger) }
      let(:project_name) { Onboarding::LearnGitlab::PROJECT_NAME }

      before do
        create(:project, name: project_name, namespace: namespace)
      end

      it 'invokes Projects::GitlabProjectsImportService' do
        expect(File).not_to receive(:open).with(template_path)
        expect_next(::Projects::GitlabProjectsImportService).not_to receive(:execute)
        expect(logger).not_to receive(:error)

        perform
      end
    end
  end
end
