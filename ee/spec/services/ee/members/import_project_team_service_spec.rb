# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::ImportProjectTeamService, feature_category: :groups_and_projects do
  describe '#execute' do
    let_it_be(:source_project) { create(:project) }
    let_it_be(:target_project) { create(:project, group: create(:group)) }
    let_it_be(:user) { create(:user) }

    let(:source_project_id) { source_project.id }
    let(:target_project_id) { target_project.id }

    subject(:import) { described_class.new(user, { id: target_project_id, project_id: source_project_id }) }

    before_all do
      source_project.add_guest(user)
      target_project.add_maintainer(user)
    end

    context 'when the project team import fails' do
      context 'when the target project has locked their membership' do
        context 'for locking via the parent group' do
          before do
            target_project.group.update!(membership_lock: true)
          end

          it 'returns unsuccessful response' do
            result = import.execute

            expect(result).to be_a(ServiceResponse)
            expect(result.error?).to be(true)
            expect(result.message).to eq('Forbidden')
            expect(result.reason).to eq(:unprocessable_entity)
          end
        end

        context 'for locking via LDAP' do
          before do
            stub_application_setting(lock_memberships_to_ldap: true)
          end

          it 'returns unsuccessful response' do
            result = import.execute

            expect(result).to be_a(ServiceResponse)
            expect(result.error?).to be(true)
            expect(result.message).to eq('Forbidden')
            expect(result.reason).to eq(:unprocessable_entity)
          end
        end
      end
    end
  end
end
