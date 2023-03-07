# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Onboarding::CreateLearnGitlabWorker, type: :worker, feature_category: :onboarding do
  describe '#perform' do
    let(:namespace) { build_stubbed(:namespace) }
    let(:template_path) { '_template_path_' }
    let(:project_name) { '_project_name_' }
    let(:user_id) { namespace.owner_id }

    subject(:perform) { described_class.new.perform(template_path, project_name, namespace.id, user_id) }

    it 'performs a no-op' do
      expect(File).not_to receive(:open).with(template_path)
      expect(::Projects::GitlabProjectsImportService).not_to receive(:new)

      perform
    end
  end
end
