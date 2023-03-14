# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEventFinder do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:subproject) { create(:project, namespace: subgroup) }

  let_it_be(:user_audit_event) { create(:user_audit_event, created_at: 3.days.ago, entity_id: user.id) }
  let_it_be(:project_audit_event) { create(:project_audit_event, entity_id: project.id, author_id: user.id, created_at: 2.days.ago) }
  let_it_be(:subproject_audit_event) { create(:project_audit_event, entity_id: subproject.id, created_at: 2.days.ago) }
  let_it_be(:group_audit_event) { create(:group_audit_event, entity_id: group.id, author_id: user.id, created_at: 1.day.ago) }

  let(:level) { Gitlab::Audit::Levels::Instance.new }
  let(:params) { {} }

  subject(:finder) { described_class.new(level: level, params: params) }

  describe '#execute' do
    subject { finder.execute }

    shared_examples 'no filtering' do
      it 'finds all the events' do
        expect(subject.count).to eq(4)
      end
    end

    context 'scoping the results' do
      context 'when project level' do
        let(:level) { Gitlab::Audit::Levels::Project.new(project: project) }

        it 'finds all project events' do
          expect(subject).to contain_exactly(project_audit_event)
        end
      end

      context 'when group level' do
        let(:level) { Gitlab::Audit::Levels::Group.new(group: group) }

        it 'finds all group events' do
          expect(subject).to contain_exactly(group_audit_event)
        end
      end

      context 'when instance level' do
        let(:level) { Gitlab::Audit::Levels::Instance.new }

        it 'finds all instance level events' do
          expect(subject).to contain_exactly(
            project_audit_event,
            subproject_audit_event,
            group_audit_event,
            user_audit_event
          )
        end
      end

      context 'when invalid level' do
        let(:level) { 'an invalid level' }

        it 'raises exception' do
          expect { subject }.to raise_error(described_class::InvalidLevelTypeError)
        end
      end
    end

    context 'filtering by entity_id' do
      context 'no entity_type provided' do
        let(:params) { { entity_id: 1 } }

        it_behaves_like 'no filtering'
      end

      context 'invalid entity_id' do
        let(:params) { { entity_type: 'User', entity_id: '0' } }

        it 'ignores entity_id and returns all events for given entity_type' do
          expect(subject.count).to eq(1)
        end
      end

      shared_examples 'finds the right event' do
        it 'finds the right event' do
          expect(subject.count).to eq(1)

          entity = subject.first

          expect(entity.entity_type).to eq(entity_type)
          expect(entity.id).to eq(audit_event.id)
        end
      end

      context 'User Event' do
        let(:params) { { entity_type: 'User', entity_id: user_audit_event.entity_id } }

        it_behaves_like 'finds the right event' do
          let(:entity_type) { 'User' }
          let(:audit_event) { user_audit_event }
        end
      end

      context 'Project Event' do
        let(:params) { { entity_type: 'Project', entity_id: project_audit_event.entity_id } }

        it_behaves_like 'finds the right event' do
          let(:entity_type) { 'Project' }
          let(:audit_event) { project_audit_event }
        end
      end

      context 'Group Event' do
        let(:params) { { entity_type: 'Group', entity_id: group_audit_event.entity_id } }

        it_behaves_like 'finds the right event' do
          let(:entity_type) { 'Group' }
          let(:audit_event) { group_audit_event }
        end
      end
    end

    context 'filtering by entity_type' do
      let(:entity_types) { subject.map(&:entity_type) }

      context 'User Event' do
        let(:params) { { entity_type: 'User' } }

        it 'finds the right user event' do
          expect(entity_types).to all(eq 'User')
        end
      end

      context 'Project Event' do
        let(:params) { { entity_type: 'Project' } }

        it 'finds the right project event' do
          expect(entity_types).to all(eq 'Project')
        end
      end

      context 'Group Event' do
        let(:params) { { entity_type: 'Group' } }

        it 'finds the right group event' do
          expect(entity_types).to all(eq 'Group')
        end
      end

      context 'invalid entity types' do
        context 'blank entity_type' do
          let(:params) { { entity_type: '' } }

          it_behaves_like 'no filtering'
        end

        context 'invalid entity_type' do
          let(:params) { { entity_type: 'Invalid Entity Type' } }

          it_behaves_like 'no filtering'
        end
      end
    end

    context 'filtering by author_id' do
      context 'no author_id provided' do
        let(:params) { { entity_type: 'Author' } }

        it_behaves_like 'no filtering'
      end

      context 'invalid author_id' do
        let(:params) { { author_id: '0' } }

        it 'ignores author_id and returns all events irrespective of entity_type' do
          expect(subject.count).to eq(4)
        end
      end

      shared_examples 'finds the right event' do
        it 'finds the right event' do
          expect(subject.count).to eq(1)

          entity = subject.first

          expect(entity.entity_type).to eq(entity_type)
          expect(entity.id).to eq(audit_event.id)
          expect(entity.author_id).to eq(audit_event.author_id)
        end
      end

      context 'Group Event' do
        let(:level) { Gitlab::Audit::Levels::Group.new(group: group) }
        let(:params) { { author_id: group_audit_event.author_id } }

        it_behaves_like 'finds the right event' do
          let(:entity_type) { 'Group' }
          let(:audit_event) { group_audit_event }
        end
      end

      context 'Project Event' do
        let(:level) { Gitlab::Audit::Levels::Project.new(project: project) }
        let(:params) { { author_id: project_audit_event.author_id } }

        it_behaves_like 'finds the right event' do
          let(:entity_type) { 'Project' }
          let(:audit_event) { project_audit_event }
        end
      end
    end

    context 'filtering by created_at' do
      context 'through created_after' do
        let(:params) { { created_after: group_audit_event.created_at } }

        it 'returns events created on or after the given date' do
          expect(subject).to contain_exactly(group_audit_event)
        end
      end

      context 'through created_before' do
        let(:params) { { created_before: user_audit_event.created_at } }

        it 'returns events created on or before the given date' do
          expect(subject).to contain_exactly(user_audit_event)
        end
      end

      context 'through created_after and created_before' do
        let(:params) { { created_after: user_audit_event.created_at, created_before: project_audit_event.created_at } }

        it 'returns events created between the given dates' do
          expect(subject).to contain_exactly(user_audit_event, project_audit_event)
        end
      end
    end

    context 'filtering by entity_username' do
      context 'User Event' do
        let(:params) { { entity_type: 'User', entity_username: user.username } }
        let(:entity_type) { 'User' }
        let(:audit_event) { user_audit_event }

        it 'finds the right event' do
          expect(subject.count).to eq(1)

          entity = subject.first

          expect(entity.entity_type).to eq(entity_type)
          expect(entity.id).to eq(audit_event.id)
          expect(entity.entity_id).to eq(user.id)
        end
      end
    end

    context 'filtering by author_username' do
      context 'username is too short' do
        let(:params) { { author_username: 'a' * (User::MIN_USERNAME_LENGTH - 1) } }

        it 'ignores author_username and returns all events irrespective of entity_type' do
          expect(subject.count).to eq(4)
        end
      end

      context 'username is too long' do
        let(:params) { { author_username: 'a' * (User::MAX_USERNAME_LENGTH + 1) } }

        it 'ignores author_username and returns all events irrespective of entity_type' do
          expect(subject.count).to eq(4)
        end
      end

      shared_examples 'finds the right event' do
        it 'finds the right event' do
          expect(subject.count).to eq(1)

          entity = subject.first

          expect(entity.entity_type).to eq(entity_type)
          expect(entity.id).to eq(audit_event.id)
          expect(entity.author_id).to eq(audit_event.author_id)
        end
      end

      context 'Instance Event' do
        let(:level) { Gitlab::Audit::Levels::Instance.new }
        let(:params) { { author_username: user.username } }

        it 'finds all the events the user authored', :aggregate_failures do
          expect(subject.count).to eq(2)

          subject.each do |entity|
            expect(entity.author_id).to eq(user.id)
          end
        end
      end

      context 'Group Event' do
        let(:level) { Gitlab::Audit::Levels::Group.new(group: group) }
        let(:params) { { author_username: user.username } }

        it_behaves_like 'finds the right event' do
          let(:entity_type) { 'Group' }
          let(:audit_event) { group_audit_event }
        end
      end

      context 'Project Event' do
        let(:level) { Gitlab::Audit::Levels::Project.new(project: project) }
        let(:params) { { author_username: user.username } }

        it_behaves_like 'finds the right event' do
          let(:entity_type) { 'Project' }
          let(:audit_event) { project_audit_event }
        end
      end
    end
  end

  describe '#find_by!' do
    let(:id) { user_audit_event.id }

    subject { finder.find_by!(id: id) } # rubocop:disable Rails/FindById

    it { is_expected.to eq(user_audit_event) }

    context 'non-existent id provided' do
      let(:id) { 'non-existent-id' }

      it 'raises exception' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
