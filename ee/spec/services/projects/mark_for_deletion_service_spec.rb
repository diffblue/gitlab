# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MarkForDeletionService do
  let(:user) { create(:user) }
  let(:marked_for_deletion_at) { nil }
  let!(:project) do
    create(:project,
      :repository,
      namespace: user.namespace,
      marked_for_deletion_at: marked_for_deletion_at)
  end

  let(:original_project_path) { project.path }
  let(:original_project_name) { project.name }

  context 'with delayed delete feature turned on' do
    before do
      stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)
    end

    context 'marking project for deletion' do
      subject { described_class.new(project, user).execute }

      it 'marks project as archived and marked for deletion' do
        expect(subject[:status]).to eq(:success)
        expect(Project.unscoped.all).to include(project)
        expect(project.archived).to eq(true)
        expect(project.marked_for_deletion_at).not_to be_nil
        expect(project.deleting_user).to eq(user)
      end

      it 'renames project name' do
        expect { subject }.to change { project.name }.from(original_project_name).to("#{original_project_name}-deleted-#{project.id}")
      end

      it 'renames project path' do
        expect { subject }.to change { project.path }.from(original_project_path).to("#{original_project_path}-deleted-#{project.id}")
      end
    end

    context 'marking project for deletion once again' do
      let(:marked_for_deletion_at) { 2.days.ago }

      it 'does not change original date' do
        result = described_class.new(project, user).execute

        expect(result[:status]).to eq(:success)
        expect(project.marked_for_deletion_at).to eq(marked_for_deletion_at.to_date)
      end
    end

    context 'audit events' do
      it 'saves audit event' do
        expect(::Gitlab::Audit::Auditor).to receive(:audit).with(
          hash_including(name: 'project_path_updated')
        ).and_call_original

        expect(::Gitlab::Audit::Auditor).to receive(:audit).with(
          hash_including(name: 'project_name_updated')
        ).and_call_original

        expect(::Gitlab::Audit::Auditor).to receive(:audit).with(
          hash_including(name: 'project_deletion_marked')
        ).and_call_original

        expect { described_class.new(project, user).execute }
          .to change { AuditEvent.count }.by(3)
      end
    end
  end

  context 'with delayed delete feature turned off' do
    context 'marking project for deletion' do
      before do
        described_class.new(project, user).execute
      end

      it 'does not change project attributes' do
        result = described_class.new(project, user).execute

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq('Cannot mark project for deletion: feature not supported')
        expect(Project.all).to include(project)

        expect(project.archived).to eq(false)
        expect(project.marked_for_deletion_at).to be_nil
        expect(project.deleting_user).to be_nil
      end
    end
  end

  describe "#project_update_service_params" do
    subject { described_class.new(project, user) }

    context 'when delayed deletion feature is not available' do
      before do
        expect(project).to receive(:feature_available?).with(:adjourned_deletion_for_projects_and_groups).and_return(false)
      end

      it "creates the params for project update service" do
        project_update_service_params = subject.send(:project_update_service_params)

        expect(project_update_service_params[:marked_for_deletion_at]).not_to be_nil
        expect(project_update_service_params[:archived]).to eq(true)
        expect(project_update_service_params[:hidden]).to eq(true)
        expect(project_update_service_params[:deleting_user]).to eq(user)
        expect(project_update_service_params[:name]).to eq("#{original_project_name}-deleted-#{project.id}")
      end
    end

    context 'when delayed deletion feature is available' do
      before do
        expect(project).to receive(:feature_available?).with(:adjourned_deletion_for_projects_and_groups).and_return(true)
      end

      it "creates the params for project update service" do
        project_update_service_params = subject.send(:project_update_service_params)

        expect(project_update_service_params[:marked_for_deletion_at]).not_to be_nil
        expect(project_update_service_params[:archived]).to eq(true)
        expect(project_update_service_params.has_key?(:hidden)).to eq(false)
        expect(project_update_service_params[:deleting_user]).to eq(user)
        expect(project_update_service_params[:name]).to eq("#{original_project_name}-deleted-#{project.id}")
      end
    end
  end
end
