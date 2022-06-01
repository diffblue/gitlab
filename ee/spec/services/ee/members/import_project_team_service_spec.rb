# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::ImportProjectTeamService do
  describe '#execute' do
    let_it_be(:source_project) { create(:project) }
    let_it_be(:target_project) { create(:project, group: create(:group)) }
    let_it_be(:user) { create(:user) }

    let(:source_project_id) { source_project.id }
    let(:target_project_id) { target_project.id }

    subject { described_class.new(user, { id: target_project_id, project_id: source_project_id }) }

    before_all do
      source_project.add_guest(user)
      target_project.add_maintainer(user)
    end

    context 'when the project team import fails' do
      context 'when the target project has locked their membership' do
        context 'via the parent group' do
          before do
            target_project.group.update!(membership_lock: true)
          end

          it 'returns false' do
            expect(subject.execute).to be(false)
          end
        end

        context 'via LDAP' do
          before do
            stub_application_setting(lock_memberships_to_ldap: true)
          end

          it 'returns false' do
            expect(subject.execute).to be(false)
          end
        end
      end
    end
  end
end
