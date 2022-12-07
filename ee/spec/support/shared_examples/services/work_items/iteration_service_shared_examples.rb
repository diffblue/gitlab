# frozen_string_literal: true

RSpec.shared_examples 'iteration change is handled' do
  before do
    stub_licensed_features(iterations: true)
  end

  shared_examples 'iteration is unchanged' do
    it 'does not change the iteration of the work item' do
      expect { subject }
        .to not_change { work_item.iteration }
    end
  end

  context 'when iteration param is not present' do
    let(:params) { {} }

    it_behaves_like 'iteration is unchanged'
  end

  context 'when user can only update but not admin the work item' do
    let(:params) { { iteration: iteration } }

    before do
      project.add_guest(user)
    end

    it_behaves_like 'iteration is unchanged'
  end

  context 'when user can admin the work item' do
    before do
      project.add_reporter(user)
    end

    let(:params) { { iteration: iteration } }

    context "when work item doesn't have iteration" do
      before do
        work_item.update!(iteration: nil)
      end

      it 'sets the iteration for the work item' do
        expect { subject }
          .to change { work_item.iteration }.to(iteration).from(nil)
      end
    end

    context "when iteration is from neither the work item's group nor its ancestors" do
      let_it_be(:other_cadence) { create(:iterations_cadence, group: create(:group)) }
      let_it_be(:other_iteration) { create(:iteration, iterations_cadence: other_cadence) }

      let(:params) { { iteration: other_iteration } }

      it_behaves_like 'iteration is unchanged'
    end
  end
end
