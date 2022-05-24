# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Projects::SetComplianceFramework do
  let_it_be(:group) { create(:group) }
  let_it_be(:framework) { create(:compliance_framework, namespace: group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:current_user) { create(:user) }

  let(:mutation) { described_class.new(object: nil, context: { current_user: current_user }, field: nil) }

  subject { mutation.resolve(project_id: GitlabSchema.id_from_object(project), compliance_framework_id: GitlabSchema.id_from_object(framework)) }

  shared_examples "the user cannot change a project's compliance framework" do
    it 'raises an exception' do
      expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end
  end

  shared_examples "the user can change a project's compliance framework" do
    it 'changes the compliance framework of the project' do
      expect { subject }.to change { project.reload.compliance_management_framework }.from(nil).to(framework)
    end

    context 'when a project had a compliance framework' do
      before do
        project.update!(compliance_management_framework: framework)
      end

      it 'can remove the compliance framework of the project' do
        expect { mutation.resolve(project_id: GitlabSchema.id_from_object(project), compliance_framework_id: nil) }.to change { project.reload.compliance_management_framework }.to(nil)
      end
    end

    it 'returns the project that was updated' do
      expect(subject).to include(project: project)
    end
  end

  describe '#resolve' do
    context 'feature is licensed' do
      before do
        stub_licensed_features(compliance_framework: true)
      end

      context 'current_user is a guest' do
        let(:current_user) { nil }

        it_behaves_like "the user cannot change a project's compliance framework"
      end

      context 'current_user is a project developer' do
        before do
          project.add_developer(current_user)
        end

        it_behaves_like "the user cannot change a project's compliance framework"
      end

      context 'current_user is a project maintainer' do
        before do
          project.add_maintainer(current_user)
        end

        it_behaves_like "the user cannot change a project's compliance framework"
      end

      context 'current_user is a project owner' do
        before do
          group.add_owner(current_user)
          project.add_owner(current_user)
        end

        it_behaves_like "the user can change a project's compliance framework"
      end
    end

    context 'feature is unlicensed' do
      before do
        stub_licensed_features(compliance_framework: false)
      end

      it_behaves_like "the user cannot change a project's compliance framework"
    end
  end
end
