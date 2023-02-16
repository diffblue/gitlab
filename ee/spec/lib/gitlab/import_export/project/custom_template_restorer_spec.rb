# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Project::CustomTemplateRestorer, feature_category: :source_code_management do
  include NonExistingRecordsHelpers

  let_it_be(:template_owner) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:custom_template) { create(:project, :repository, group: group) }
  let_it_be(:project_member) { create(:project_member, :owner, user: template_owner, source: custom_template) }
  let_it_be(:importable) do
    project = create(:project, :repository, group: group, import_type: 'gitlab_custom_project_template')
    ProjectImportData.new(project: project, data: { 'template_project_id' => custom_template.id }).save!
    project
  end

  subject { described_class.new(project: importable, shared: importable.import_export_shared, user: user) }

  before do
    allow(::Gitlab::CurrentSettings).to(receive(:custom_project_templates_enabled?)).and_return(true)
  end

  shared_examples 'successfully execute the restorers' do
    [
      Gitlab::ImportExport::Project::ProjectHooksRestorer,
      Gitlab::ImportExport::Project::DeployKeysRestorer
    ].each do |restorer|
      it "calls the #{restorer}" do
        fake_restorer = instance_double(restorer.to_s)

        expect(fake_restorer).to receive(:restore).and_return(true).once
        expect(restorer).to receive(:new).and_return(fake_restorer).once

        restored = subject.restore
        expect(restored).to eq(true)
      end
    end
  end

  shared_examples 'do not execute the restorers' do
    [
      Gitlab::ImportExport::Project::ProjectHooksRestorer,
      Gitlab::ImportExport::Project::DeployKeysRestorer
    ].each do |restorer|
      it "calls the #{restorer}" do
        fake_restorer = instance_double(restorer.to_s)

        expect(fake_restorer).not_to receive(:restore)
        expect(restorer).not_to receive(:new)

        restored = subject.restore
        expect(restored).to eq(true)
      end
    end
  end

  context 'when export is a gitlab_custom_project_template_import' do
    before do
      importable.import_data.data = { 'template_project_id' => custom_template.id }
      importable.import_type = 'gitlab_custom_project_template'
      importable.save!
    end

    context 'with admin user' do
      let(:user) { create(:admin) }

      before do
        allow(user).to receive(:can_admin_all_resources?).and_return(true)
      end

      it_behaves_like 'successfully execute the restorers'
    end

    context 'with group owner' do
      let(:user) do
        user = create(:user)
        create(:group_member, :owner, user: user, source: group)

        user
      end

      it_behaves_like 'successfully execute the restorers'
    end

    context 'with custom_template owner' do
      let(:user) { template_owner }

      it_behaves_like 'successfully execute the restorers'
    end

    context 'with random member user' do
      let!(:user) { create(:user) }
      let!(:membership) { create(:project_member, :maintainer, user: user, source: custom_template) }

      it_behaves_like 'do not execute the restorers'
    end

    context 'with no template_project_id in importable import data' do
      before do
        importable.import_data.data = {}
        importable.save!
      end

      let(:user) { create(:admin) }

      it_behaves_like 'do not execute the restorers'
    end

    context 'with a un-existing template_project_id in importable import data' do
      before do
        importable.import_data.data = { 'template_project_id' => non_existing_record_id }
        importable.save!
      end

      let(:user) { create(:admin) }

      it_behaves_like 'do not execute the restorers'
    end
  end

  context 'when import_type is not a gitlab_custom_project_template_import' do
    before do
      importable.import_data.data = { 'template_project_id' => custom_template.id }
      importable.import_type = 'gitlab_project'
      importable.save!
    end

    let(:user) { create(:admin) }

    it_behaves_like 'do not execute the restorers'
  end
end
