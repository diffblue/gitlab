# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Iterations::CreateService do
  shared_examples 'iterations create service' do
    let_it_be(:user) { create(:user) }

    before_all do
      parent.add_reporter(user)
    end

    context 'iterations feature enabled' do
      before do
        stub_licensed_features(iterations: true)
      end

      describe '#execute' do
        let(:params) do
          {
              title: 'v2.1.9',
              description: 'Patch release to fix security issue',
              start_date: Time.current.to_s,
              due_date: 1.day.from_now.to_s
          }
        end

        let(:response) { described_class.new(parent, user, params).execute }
        let(:iteration) { response.payload[:iteration] }
        let(:errors) { response.payload[:errors] }

        context 'valid params' do
          it 'creates an iteration' do
            allow_next_instance_of(Iteration) do |iteration|
              allow(iteration).to receive(:skip_project_validation).and_return(true)
            end

            expect(response.success?).to be_truthy
            expect(iteration).to be_persisted
            expect(iteration.title).to eq('v2.1.9')
          end
        end

        context 'invalid params' do
          let(:params) do
            {
                description: 'Patch release to fix security issue'
            }
          end

          it 'does not create an iteration but returns errors' do
            allow_next_instance_of(Iteration) do |iteration|
              allow(iteration).to receive(:skip_project_validation).and_return(true)
            end

            expect(response.error?).to be_truthy
            expect(errors.messages).to match({ due_date: ["can't be blank"], start_date: ["can't be blank"] })
          end
        end

        context 'no permissions' do
          before do
            parent.add_guest(user)
          end

          it 'is not allowed' do
            expect(response.error?).to be_truthy
            expect(response.message).to eq('Operation not allowed')
          end
        end
      end
    end

    context 'iterations feature disabled' do
      before do
        stub_licensed_features(iterations: false)
      end

      describe '#execute' do
        let(:params) { { title: 'a' } }
        let(:response) { described_class.new(parent, user, params).execute }

        it 'is not allowed' do
          expect(response.error?).to be_truthy
          expect(response.message).to eq('Operation not allowed')
        end
      end
    end
  end

  context 'for projects' do
    let_it_be(:parent, refind: true) { create(:project, namespace: create(:group)) }

    it_behaves_like 'iterations create service'
  end

  context 'for groups' do
    let_it_be(:group) { create(:group) }

    context 'group without cadences' do
      let_it_be(:parent, refind: true) { group }

      it_behaves_like 'iterations create service'
    end

    context 'group with a cadence' do
      let_it_be(:cadence) { create(:iterations_cadence, group: group) }
      let_it_be(:parent, refind: true) { group }

      it_behaves_like 'iterations create service'
    end

    context 'group with multiple cadences', :aggregate_failures do
      let_it_be(:parent, refind: true) { group }

      let(:base_params) do
        {
          title: 'v2.1.9',
          description: 'Patch release to fix security issue',
          start_date: Time.current.to_s,
          due_date: 1.day.from_now.to_s
        }
      end

      let(:response) { described_class.new(parent, user, params).execute }
      let(:saved_iteration) { response.payload[:iteration] }

      it_behaves_like 'iterations create service'

      context 'with specific cadence being passed as param' do
        let_it_be(:user) { create(:user) }
        let_it_be(:cadences) { create_list(:iterations_cadence, 2, group: group) }

        let(:params) { base_params.merge(iterations_cadence_id: cadences.last.id) }

        before do
          parent.add_developer(user)
        end

        it 'creates an iteration' do
          expect(response).to be_success
          expect(saved_iteration).to be_persisted
          expect(saved_iteration.iterations_cadence_id).to eq(cadences.last.id)
        end
      end

      context 'when iteration_cadences FF is disabled' do
        let_it_be(:user) { create(:user) }
        let_it_be(:group) { create(:group) }
        let_it_be(:first_legacy_cadence) { build(:iterations_cadence, group: group, automatic: false).tap { |cadence| cadence.save!(validate: false) } }
        let_it_be(:automatic_cadence) { create(:iterations_cadence, group: group) }
        let_it_be(:other_iteration) { create(:iteration, iterations_cadence: automatic_cadence) }
        let_it_be(:parent, refind: true) { group }

        let(:params) { base_params }
        let(:ordered_cadences) { group.iterations_cadences.order(id: :asc) }

        before do
          stub_feature_flags(iteration_cadences: false)
          parent.add_developer(user)
        end

        it 'creates an iteration in the default (first) cadence' do
          expect(response).to be_success
          expect(saved_iteration).to be_persisted
          expect(saved_iteration.title).to eq('v2.1.9')
          expect(saved_iteration.iterations_cadence_id).to eq(first_legacy_cadence.id)
        end

        it 'does not update the iterations from the non-default cadences' do
          expect(response).to be_success
          expect(other_iteration.iterations_cadence_id).to eq(automatic_cadence.id)
        end
      end
    end
  end
end
