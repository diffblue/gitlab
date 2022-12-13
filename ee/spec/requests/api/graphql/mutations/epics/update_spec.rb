# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Epics::Update, feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:label_1) { create(:group_label, title: "a", group: group) }
  let(:label_2) { create(:group_label, title: "b", group: group) }
  let(:label_3) { create(:group_label, title: "c", group: group) }
  let(:epic) { create(:epic, group: group, title: 'original title', labels: [label_2]) }

  let(:attributes) do
    {
      title: 'updated title',
      description: 'some description',
      start_date_fixed: '2019-09-17',
      due_date_fixed: '2019-09-18',
      start_date_is_fixed: true,
      due_date_is_fixed: true,
      confidential: true
    }
  end

  let(:params) { { group_path: group.full_path, iid: epic.iid.to_s }.merge(attributes) }
  let(:mutation) do
    graphql_mutation(:update_epic, params)
  end

  def mutation_response
    graphql_mutation_response(:update_epic)
  end

  context 'when the user does not have permission' do
    before do
      stub_licensed_features(epics: true)
    end

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not update the epic' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(epic.reload.title).to eq('original title')
    end
  end

  context 'when the user has permission' do
    before do
      epic.group.add_developer(current_user)
    end

    context 'when epics are disabled' do
      before do
        stub_licensed_features(epics: false)
      end

      it_behaves_like 'a mutation that returns top-level errors',
        errors: ['The resource that you are attempting to access does not '\
                 'exist or you don\'t have permission to perform this action']
    end

    context 'when epics are enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      it 'updates the epic' do
        post_graphql_mutation(mutation, current_user: current_user)

        epic_hash = mutation_response['epic']
        expect(epic_hash['title']).to eq('updated title')
        expect(epic_hash['description']).to eq('some description')
        expect(epic_hash['startDateFixed']).to eq('2019-09-17')
        expect(epic_hash['startDateIsFixed']).to eq(true)
        expect(epic_hash['dueDateFixed']).to eq('2019-09-18')
        expect(epic_hash['dueDateIsFixed']).to eq(true)
        expect(epic_hash['confidential']).to eq(true)
      end

      context 'when closing the epic' do
        let(:attributes) { { state_event: 'CLOSE' } }

        it 'closes open epic' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(epic.reload).to be_closed
        end
      end

      context 'when reopening the epic' do
        let(:attributes) { { state_event: 'REOPEN' } }

        it 'allows epic to be reopend' do
          epic.update!(state: 'closed')

          post_graphql_mutation(mutation, current_user: current_user)

          expect(epic.reload).to be_open
        end
      end

      context 'when changing labels of the epic' do
        let(:mutation) do
          graphql_mutation(:update_epic, params) do
            <<~QL
                epic {
                   labels {
                     nodes {
                       id
                     }
                   }
                }
                errors
            QL
          end
        end

        context 'by ID' do
          let(:attributes) { { add_label_ids: [label_1.id, label_3.id], remove_label_ids: label_2.id } }

          it 'adds and removes labels correctly' do
            post_graphql_mutation(mutation, current_user: current_user)

            expect(epic.reload.labels).to match_array([label_1, label_3])
          end

          context 'when labels are added' do
            let(:attributes) { { add_label_ids: [label_1.id, label_3.id] } }

            it 'adds labels correctly and keeps the title ordering' do
              post_graphql_mutation(mutation, current_user: current_user)

              labels_ids = mutation_response['epic']['labels']['nodes'].map { |l| l['id'] }
              expected_label_ids = [label_1, label_2, label_3].map { |l| l.to_global_id.to_s }

              expect(labels_ids).to eq(expected_label_ids)
            end
          end
        end

        context 'by title' do
          let(:attributes) { { add_labels: [label_1.title, label_3.title], remove_labels: label_2.title } }

          it 'adds and removes labels correctly' do
            post_graphql_mutation(mutation, current_user: current_user)

            expect(epic.reload.labels).to match_array([label_1, label_3])
          end

          context 'when labels are added' do
            let(:attributes) { { add_labels: [label_1.title, label_3.title] } }

            it 'adds labels correctly and keeps the title ordering' do
              post_graphql_mutation(mutation, current_user: current_user)

              labels_ids = mutation_response['epic']['labels']['nodes'].map { |l| l['id'] }
              expected_label_ids = [label_1, label_2, label_3].map { |l| l.to_global_id.to_s }

              expect(labels_ids).to eq(expected_label_ids)
            end
          end
        end
      end

      context 'when there are ActiveRecord validation errors' do
        let(:attributes) { { title: '' } }

        it_behaves_like 'a mutation that returns errors in the response',
          errors: ["Title can't be blank"]

        it 'does not update the epic' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(mutation_response['epic']['title']).to eq('original title')
        end
      end

      context 'when the list of attributes is empty' do
        let(:attributes) { {} }

        it_behaves_like 'a mutation that returns top-level errors',
          errors: ['The list of epic attributes is empty']
      end
    end
  end
end
