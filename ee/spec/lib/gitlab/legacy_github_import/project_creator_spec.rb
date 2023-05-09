# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::LegacyGithubImport::ProjectCreator, feature_category: :importers do
  let(:user) { create(:user) }
  let(:namespace) { create(:group) }

  let(:repo) do
    {
      login: 'vim',
      name: 'vim',
      description: 'Vim',
      full_name: 'asd/vim',
      clone_url: 'https://gitlab.com/asd/vim.git',
      private: false,
      has_wiki: false
    }
  end

  subject(:service) do
    described_class.new(repo, repo[:name], namespace, user, github_access_token: 'asdffg')
  end

  before do
    namespace.add_owner(user)
    stub_licensed_features(ci_cd_projects: true)
    stub_application_setting(import_sources: %w[github])

    allow_any_instance_of(EE::Project).to receive(:add_import_job)
    allow_any_instance_of(CiCd::SetupProject).to receive(:setup_external_service)
  end

  describe '#execute' do
    context 'creating a CI/CD only project' do
      let(:params) { { ci_cd_only: true } }

      it 'creates a project' do
        expect { service.execute(params) }.to change(Project, :count).by(1)
      end

      it 'calls the service to set up the project' do
        expect(CiCd::SetupProject).to receive_message_chain(:new, :execute)

        service.execute(params)
      end
    end

    context 'creating a regular project' do
      let(:params) { {} }

      it 'creates a project' do
        expect { service.execute(params) }.to change(Project, :count).by(1)
      end

      it "doesn't apply any special setup" do
        expect(CiCd::SetupProject).not_to receive(:new)

        service.execute(params)
      end
    end
  end
end
