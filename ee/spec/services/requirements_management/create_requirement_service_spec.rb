# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RequirementsManagement::CreateRequirementService do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }

  let(:params) { { title: 'foo', author_id: other_user.id, created_at: 2.days.ago } }

  subject { described_class.new(project: project, current_user: user, params: params).execute }

  describe '#execute' do
    before do
      stub_licensed_features(requirements: true)
    end

    context 'when user can create requirements' do
      before do
        project.add_reporter(user)
      end

      it 'creates new requirement' do
        expect { subject }.to change { RequirementsManagement::Requirement.count }.by(1)
      end

      it 'uses only permitted params' do
        requirement = subject

        expect(requirement).to be_persisted
        expect(requirement.title).to eq(params[:title])
        expect(requirement.state).to eq('opened')
        expect(requirement.created_at).not_to eq(params[:created_at])
        expect(requirement.author_id).not_to eq(params[:author_id])
      end

      context 'when syncing with requirement issues' do
        it 'creates an issue and a requirement' do
          expect { subject }.to change { Issue.count }.by(1)
            .and change { RequirementsManagement::Requirement.count }.by(1)
        end

        it 'creates an associated issue of type requirement with same attributes' do
          requirement = subject
          issue = requirement.reload.requirement_issue

          expect(issue).to be_persisted
          expect(issue.title).to eq(requirement.title)
          expect(issue.description).to eq(requirement.description)
          expect(issue.author).to eq(requirement.author)
          expect(issue.project).to eq(requirement.project)
          expect(issue.requirement?).to eq(true)
        end

        context 'when creation of requirement fails' do
          let_it_be(:requirement2) { create(:requirement, project: project, state: :opened, author: user) }

          it 'does not create issue' do
            allow_next_instance_of(RequirementsManagement::Requirement) do |instance|
              allow(instance).to receive(:valid?).and_return(false)
              allow(instance).to receive(:valid?).with(:before_requirement_issue).and_return(false)
            end

            expect { subject }.to change { Issue.count }.by(0)
              .and change { RequirementsManagement::Requirement.count }.by(0)
          end
        end

        context 'when creation of issue fails' do
          before do
            allow_next_instance_of(Issue) do |instance|
              allow(instance).to receive(:valid?).and_return(false)
            end
          end

          it 'does not create requirement' do
            expect { subject }.to change { Issue.count }.by(0)
              .and change { RequirementsManagement::Requirement.count }.by(0)
          end

          it 'logs error' do
            expect(::Gitlab::AppLogger).to receive(:info).with(a_hash_including(message: /Associated issue/))

            subject
          end
        end
      end
    end

    context 'when user is not allowed to create requirements' do
      it 'raises an exception' do
        expect { subject }.to raise_exception(Gitlab::Access::AccessDeniedError)
      end
    end
  end
end
