# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuable::BulkUpdateService, feature_category: :team_planning do
  let_it_be(:user)  { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project1) { create(:project, :repository, group: group) }
  let_it_be(:project2) { create(:project, :repository, group: group) }

  subject { described_class.new(parent, user, params).execute(type) }

  shared_examples 'updates issuables attribute' do |attribute|
    it 'succeeds and returns the correct number of issuables updated' do
      expect(subject.success?).to be_truthy
      expect(subject.payload[:count]).to eq(issuables.count)
      issuables.each do |issuable|
        expect(issuable.reload.send(attribute)).to eq(new_value)
      end
    end
  end

  shared_examples 'does not update issuables attribute' do |attribute|
    it 'does not update attribute' do
      issuables.each do |issuable|
        expect { subject }.not_to change { issuable.send(attribute) }
      end
    end
  end

  context 'with issues' do
    let_it_be(:type) { 'issue' }
    let_it_be(:parent) { group }

    let(:issue1) { create(:issue, project: project1, health_status: :at_risk) }
    let(:issue2) { create(:issue, project: project2, health_status: :at_risk) }
    let(:issuables) { [issue1, issue2] }
    let(:epic) { create(:epic, group: group) }

    before do
      group.add_reporter(user)
    end

    context 'updating health status and epic' do
      let(:params) do
        {
          issuable_ids: issuables.map(&:id),
          health_status: :on_track,
          epic_id: epic.id
        }
      end

      context 'when features are enabled' do
        before do
          stub_licensed_features(epics: true, issuable_health_status: true)
        end

        it 'succeeds and returns the correct number of issuables updated' do
          expect(subject.success?).to be_truthy
          expect(subject.payload[:count]).to eq(issuables.count)
          issuables.each do |issuable|
            issuable.reload
            expect(issuable.health_status).to eq('on_track')
            expect(issuable.epic).to eq(epic)
          end
        end

        context "when params value is '0'" do
          let(:params) { { issuable_ids: issuables.map(&:id), health_status: '0', epic_id: '0' } }

          it 'succeeds and remove values' do
            expect(subject.success?).to be_truthy
            expect(subject.payload[:count]).to eq(issuables.count)
            issuables.each do |issuable|
              issuable.reload
              expect(issuable.health_status).to be_nil
              expect(issuable.epic).to be_nil
            end
          end
        end

        context 'when epic param is incorrect' do
          let(:external_epic) { create(:epic, group: create(:group, :private)) }
          let(:params) do
            {
              issuable_ids: issuables.map(&:id),
              epic_id: external_epic.id
            }
          end

          it 'returns error' do
            expect(subject.message).to eq('Epic not found for given params')
            expect(subject.status).to eq(:error)
            expect(subject.http_status).to eq(422)
          end
        end
      end

      context 'when feature issuable_health_status is disabled' do
        before do
          stub_licensed_features(issuable_health_status: false)
        end

        it_behaves_like 'does not update issuables attribute', :health_status
      end

      context 'when user can not update issues' do
        before do
          group.add_guest(user)
        end

        it_behaves_like 'does not update issuables attribute', :health_status
        it_behaves_like 'does not update issuables attribute', :epic
      end

      context 'when user can not admin epic' do
        let(:epic3) { create(:epic, group: create(:group)) }
        let(:params) { { issuable_ids: issuables.map(&:id), epic_id: epic3.id } }

        it_behaves_like 'does not update issuables attribute', :epic
      end
    end

    describe 'updating iterations' do
      shared_examples 'updates iterations' do
        it 'succeeds' do
          result = bulk_update(issuables, sprint_id: iteration.id)

          expect(result.success?).to be_truthy
          expect(result.payload[:count]).to eq(issuables.count)
        end

        it 'updates the issuables iteration' do
          bulk_update(issuables, sprint_id: iteration.id)

          issuables.each do |issuable|
            expect(issuable.reload.iteration).to eq(iteration)
          end
        end
      end

      context 'at group level' do
        let_it_be(:group) { create(:group) }
        let_it_be(:iteration) { create(:iteration, iterations_cadence: create(:iterations_cadence, group: group)) }
        let_it_be(:project)   { create(:project, :repository, group: group) }

        let(:parent) { group }

        context 'when issues' do
          let_it_be(:issue1)    { create(:issue, project: project) }
          let_it_be(:issue2)    { create(:issue, project: project) }
          let_it_be(:issuables) { [issue1, issue2] }

          it_behaves_like 'updates iterations'
        end
      end

      context 'at project level' do
        let_it_be(:group) { create(:group) }
        let_it_be(:project) { create(:project, group: group) }
        let_it_be(:issuables) { [create(:issue, project: project)] }
        let_it_be(:iteration) { create(:iteration, iterations_cadence: create(:iterations_cadence, group: group)) }

        let(:parent) { project }

        before do
          group.add_reporter(user)
        end

        it_behaves_like 'updates iterations'
      end
    end
  end

  context 'with epics' do
    let_it_be(:type) { 'epic' }
    let_it_be(:parent) { group }

    let(:epic1) { create(:epic, group: group, labels: [label1]) }
    let(:epic2) { create(:epic, group: group, labels: [label1]) }

    let_it_be(:label1) { create(:group_label, group: group) }

    before do
      group.add_reporter(user)
      stub_licensed_features(epics: true)
    end

    describe 'updating labels' do
      let_it_be(:label2) { create(:group_label, group: group, title: 'Bug') }
      let_it_be(:label3) { create(:group_label, group: group, title: 'suggestion') }

      let(:issuables) { [epic1, epic2] }
      let(:params) do
        {
          issuable_ids: issuables.map(&:id).join(','),
          add_label_ids: [label2.id, label3.id],
          remove_label_ids: [label1.id]
        }
      end

      context 'when epics are enabled' do
        let(:new_value) { [label2, label3] }

        it_behaves_like 'updates issuables attribute', :labels

        context 'when epics have different labels' do
          let(:label4) { create(:group_label, group: group, title: 'feature') }
          let(:epic1) { create(:epic, group: group, labels: [label1, label4]) }

          it 'keeps existing labels' do
            expect(subject.success?).to be_truthy
            expect(subject.payload[:count]).to eq(issuables.count)

            expect(epic1.reload.labels).to contain_exactly(label4, label2, label3)
            expect(epic2.reload.labels).to contain_exactly(label2, label3)
          end
        end
      end

      context 'when epics are disabled' do
        before do
          stub_licensed_features(epics: false)
        end

        it_behaves_like 'does not update issuables attribute', :labels
      end

      context 'when issuable_ids contain external epics' do
        let(:epic3) { create(:epic, group: create(:group, parent: group), labels: [label1]) }
        let(:outer_epic) { create(:epic, labels: [label1]) }
        let(:params) { { issuable_ids: [epic1.id, epic3.id, outer_epic.id], add_label_ids: [label3.id] } }

        it 'updates epics that belong to the parent group or descendants' do
          expect(subject.success?).to be_truthy
          expect(subject.payload[:count]).to eq(2)

          expect(epic1.reload.labels).to eq([label1, label3])
          expect(epic3.reload.labels).to eq([label1, label3])
          expect(outer_epic.reload.labels).to eq([label1])
        end
      end
    end
  end

  def bulk_update(issuables, extra_params = {})
    bulk_update_params = extra_params
                           .reverse_merge(issuable_ids: Array(issuables).map(&:id).join(','))

    type = Array(issuables).first.model_name.param_key
    Issuable::BulkUpdateService.new(parent, user, bulk_update_params).execute(type)
  end
end
