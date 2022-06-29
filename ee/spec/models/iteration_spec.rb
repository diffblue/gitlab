# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Iteration, feature_category: :team_planning do
  using RSpec::Parameterized::TableSyntax
  include ActiveSupport::Testing::TimeHelpers

  let(:set_cadence) { nil }
  let(:expected_sequence) { (1..iteration_cadence.reload.iterations.size).to_a }
  let(:ordered_iterations) { iteration_cadence.iterations.order(:start_date) }

  it_behaves_like 'AtomicInternalId' do
    let(:internal_id_attribute) { :iid }
    let(:instance) { build(:iteration, group: create(:group)) }
    let(:scope) { :group }
    let(:scope_attrs) { { namespace: instance.group } }
    let(:usage) { :sprints }
  end

  describe '#display_text' do
    let_it_be(:group) { create(:group) }
    let_it_be(:iterations_cadence) { create(:iterations_cadence, title: "Plan cadence", group: group) }
    let_it_be(:iteration) { create(:iteration, iterations_cadence: iterations_cadence, start_date: Date.new(2022, 9, 30), due_date: Date.new(2022, 10, 4)) }

    subject { iteration.display_text }

    it { is_expected.to eq('Plan cadence Sep 30, 2022 - Oct 4, 2022') }
  end

  describe '#period' do
    let_it_be(:group) { create(:group) }
    let_it_be(:iterations_cadence) { create(:iterations_cadence, group: group) }
    let_it_be(:iteration) { create(:iteration, iterations_cadence: iterations_cadence, start_date: Date.new(2022, 9, 30), due_date: Date.new(2022, 10, 4)) }

    subject { iteration.period }

    it { is_expected.to eq('Sep 30, 2022 - Oct 4, 2022') }
  end

  describe '#title' do
    let_it_be(:iteration) { create(:iteration, title: "foobar", group: create(:group)) }

    it 'updates title to a blank value', :aggregate_failures do
      iteration.update!(title: "")

      expect(iteration.title).to be_nil
    end
  end

  describe '#merge_requests_enabled?' do
    it 'returns false' do
      expect(build(:iteration).merge_requests_enabled?).to eq false
    end
  end

  describe '.reference_pattern' do
    let_it_be(:group) { create(:group) }
    let_it_be(:iteration_cadence) { create(:iterations_cadence, group: group) }
    let_it_be(:project) { create(:project, group: group) }

    subject { described_class.reference_pattern }

    let(:captures) { subject.match(reference).named_captures }

    context 'when iteration id is provided' do
      let(:reference) { 'gitlab-org/gitlab-ce*iteration:123' }

      it 'correctly detects the iteration' do
        expect(captures).to eq(
          'namespace' => 'gitlab-org',
          'project' => 'gitlab-ce',
          'iteration_id' => '123',
          'iteration_name' => nil
        )
      end
    end

    context 'when iteration name is provided' do
      let(:reference) { 'gitlab-org/gitlab-ce*iteration:my-iteration' }

      it 'correctly detects the iteration' do
        expect(captures).to eq(
          'namespace' => 'gitlab-org',
          'project' => 'gitlab-ce',
          'iteration_id' => nil,
          'iteration_name' => 'my-iteration'
        )
      end
    end

    context 'when reference includes tags' do
      let(:reference) { '<p>gitlab-org/gitlab-ce*iteration:my-iteration</p>' }

      it 'correctly detects the iteration' do
        expect(captures).to eq(
          'namespace' => 'gitlab-org',
          'project' => 'gitlab-ce',
          'iteration_id' => nil,
          'iteration_name' => 'my-iteration'
        )
      end
    end
  end

  describe '.filter_by_state' do
    let_it_be(:group) { create(:group) }
    let_it_be(:iteration_cadence) { create(:iterations_cadence, group: group) }
    let_it_be(:closed_iteration) { create(:iteration, :closed, :skip_future_date_validation, group: group, start_date: 8.days.ago, due_date: 2.days.ago) }
    let_it_be(:current_iteration) { create(:iteration, :current, :skip_future_date_validation, group: group, start_date: 1.day.ago, due_date: 6.days.from_now) }
    let_it_be(:upcoming_iteration) { create(:iteration, :upcoming, group: group, start_date: 1.week.from_now, due_date: 2.weeks.from_now) }

    shared_examples_for 'filter_by_state' do
      it 'filters by the given state' do
        expect(described_class.filter_by_state(Iteration.all, state)).to match(expected_iterations)
      end
    end

    context 'filtering by closed iterations' do
      it_behaves_like 'filter_by_state' do
        let(:state) { 'closed' }
        let(:expected_iterations) { [closed_iteration] }
      end
    end

    context 'filtering by started iterations' do
      it_behaves_like 'filter_by_state' do
        let(:state) { 'current' }
        let(:expected_iterations) { [current_iteration] }
      end
    end

    context 'filtering by opened iterations' do
      it_behaves_like 'filter_by_state' do
        let(:state) { 'opened' }
        let(:expected_iterations) { [current_iteration, upcoming_iteration] }
      end
    end

    context 'filtering by upcoming iterations' do
      it_behaves_like 'filter_by_state' do
        let(:state) { 'upcoming' }
        let(:expected_iterations) { [upcoming_iteration] }
      end
    end

    context 'filtering by "all"' do
      it_behaves_like 'filter_by_state' do
        let(:state) { 'all' }
        let(:expected_iterations) { [closed_iteration, current_iteration, upcoming_iteration] }
      end
    end

    context 'filtering by nonexistent filter' do
      it 'returns no results' do
        expect do
          described_class.filter_by_state(Iteration.all, 'unknown')
        end.to raise_error(ArgumentError, "Unknown state filter: unknown")
      end
    end
  end

  context 'Validations' do
    let_it_be(:group) { create(:group) }
    let_it_be(:iteration_cadence) { create(:iterations_cadence, group: group) }

    subject { build(:iteration, group: group, iterations_cadence: iteration_cadence, start_date: start_date, due_date: due_date) }

    describe "#uniqueness_of_title" do
      context "per group" do
        let(:iteration) { create(:iteration, iterations_cadence: iteration_cadence) }

        it "accepts the same title in the same group with different cadence" do
          new_cadence = create(:iterations_cadence, group: group)
          new_iteration = create(:iteration, iterations_cadence: new_cadence, title: iteration.title)

          expect(new_iteration.iterations_cadence).not_to eq(iteration.iterations_cadence)
          expect(new_iteration).to be_valid
        end

        it "does not accept the same title when in the same cadence" do
          new_iteration = described_class.new(iterations_cadence: iteration_cadence, title: iteration.title)

          expect(new_iteration).not_to be_valid
        end
      end
    end

    describe '#dates_do_not_overlap' do
      let_it_be(:existing_iteration) { create(:iteration, iterations_cadence: iteration_cadence, start_date: 4.days.from_now, due_date: 1.week.from_now) }

      context 'when no Iteration dates overlap' do
        let(:start_date) { 2.weeks.from_now }
        let(:due_date) { 3.weeks.from_now }

        it { is_expected.to be_valid }
      end

      context 'when updated iteration dates overlap with its own dates' do
        it 'is valid' do
          existing_iteration.start_date = 5.days.from_now

          expect(existing_iteration).to be_valid
        end
      end

      context 'when dates overlap' do
        let(:start_date) { 5.days.from_now }
        let(:due_date) { 6.days.from_now }

        shared_examples_for 'overlapping dates' do
          shared_examples_for 'invalid dates' do
            it 'is not valid' do
              expect(subject).not_to be_valid
              expect(subject.errors[:base]).to include('Dates cannot overlap with other existing Iterations within this iterations cadence')
            end
          end

          context 'when start_date overlaps' do
            let(:start_date) { 5.days.from_now }
            let(:due_date) { 3.weeks.from_now }

            it_behaves_like 'invalid dates'
          end

          context 'when due_date overlaps' do
            let(:start_date) { Time.current }
            let(:due_date) { 6.days.from_now }

            it_behaves_like 'invalid dates'
          end

          context 'when both overlap' do
            it_behaves_like 'invalid dates'
          end
        end

        context 'group' do
          it_behaves_like 'overlapping dates' do
            let(:constraint_name) { 'iteration_start_and_due_date_iterations_cadence_id_constraint' }
          end

          context 'different group' do
            let(:group) { create(:group) }
            let(:iteration_cadence) { create(:iterations_cadence, group: group) }

            it { is_expected.to be_valid }

            it 'does not trigger exclusion constraints' do
              expect { subject.save! }.not_to raise_exception
            end
          end

          context 'sub-group' do
            let(:subgroup) { create(:group, parent: group) }
            let(:subgroup_ic) { create(:iterations_cadence, group: subgroup) }

            subject { build(:iteration, group: subgroup, iterations_cadence: subgroup_ic, start_date: start_date, due_date: due_date) }

            it { is_expected.to be_valid }
          end
        end
      end
    end

    describe '#future_date' do
      context 'when dates are in the future' do
        let(:start_date) { Time.current }
        let(:due_date) { 1.week.from_now }

        it { is_expected.to be_valid }
      end

      context 'when start_date is in the past' do
        let(:start_date) { 1.week.ago }
        let(:due_date) { 1.week.from_now }

        it { is_expected.to be_valid }
      end

      context 'when due_date is in the past' do
        let(:start_date) { 2.weeks.ago }
        let(:due_date) { 1.week.ago }

        it { is_expected.to be_valid }
      end

      context 'when due_date is before start date' do
        let(:start_date) { Time.current }
        let(:due_date) { 1.week.ago }

        it 'is not valid' do
          expect(subject).not_to be_valid
          expect(subject.errors[:due_date]).to include('must be greater than start date')
        end
      end

      context 'when start_date is over 500 years in the future' do
        let(:start_date) { 501.years.from_now }
        let(:due_date) { Time.current }

        it 'is not valid' do
          expect(subject).not_to be_valid
          expect(subject.errors[:start_date]).to include('cannot be more than 500 years in the future')
        end
      end

      context 'when due_date is over 500 years in the future' do
        let(:start_date) { Time.current }
        let(:due_date) { 501.years.from_now }

        it 'is not valid' do
          expect(subject).not_to be_valid
          expect(subject.errors[:due_date]).to include('cannot be more than 500 years in the future')
        end
      end
    end

    describe 'title' do
      subject { build(:iteration, iterations_cadence: iteration_cadence, title: '<img src=x onerror=prompt(1)>') }

      it 'sanitizes user intput', :aggregate_failures do
        expect(subject.title).to be_blank
      end
    end
  end

  describe 'relations' do
    context 'deferrable uniqueness constraint on iterations_cadence_id and sequence', :delete do
      let!(:iterations_cadence) { create(:iterations_cadence, group: create(:group)) }
      let!(:iteration) { create(:iteration, :with_due_date, sequence: 1, iterations_cadence: iterations_cadence, start_date: 1.week.from_now) }

      before do
        # Avoid `update_iteration_sequences` after_save callback to re-assign unique sequences
        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:update_iteration_sequences).and_return(true)
        end
      end

      context "create" do
        it "raises an error on creation with a duplicate sequence number within a cadence" do
          expect do
            create(:iteration, :with_due_date, sequence: 1, iterations_cadence: iterations_cadence, start_date: 2.weeks.from_now)
          end.to raise_error(ActiveRecord::RecordNotUnique)
        end

        it "does not raise an error on creation with a unique sequence number within a cadence", :aggregate_failures do
          expect do
            create(:iteration, :with_due_date, sequence: 2, iterations_cadence: iterations_cadence, start_date: 2.weeks.from_now)
          end.not_to raise_error
        end
      end

      context "update" do
        let!(:new_iteration) { create(:iteration, :with_due_date, sequence: 2, iterations_cadence: iterations_cadence, start_date: 2.weeks.from_now) }

        it "raises an error on update with a duplicate sequence number within a cadence" do
          expect do
            new_iteration.update!(sequence: 1)
          end.to raise_error(ActiveRecord::RecordNotUnique)
        end
      end
    end

    context 'deferrable exclusion constraint on start_date, due_date and iterations_cadence_id', :delete do
      let!(:iterations_cadence) { create(:iterations_cadence, group: create(:group)) }
      let!(:iteration1) { create(:iteration, iterations_cadence: iterations_cadence, start_date: 4.days.from_now, due_date: 1.week.from_now) }

      context 'with invalid dates' do
        subject { build(:iteration, iterations_cadence: iterations_cadence, start_date: start_date, due_date: due_date) }

        shared_examples 'invalid dates raise PG exclusion error' do
          it 'prevents invalid dates with a PG exclusion constraint at the end of a transaction' do
            subject.validate # to generate iid/etc
            expect { subject.save!(validate: false) }.to raise_exception(ActiveRecord::StatementInvalid, /PG::ExclusionViolation/)
          end
        end

        context 'when start_date overlaps' do
          let(:start_date) { 5.days.from_now }
          let(:due_date) { 3.weeks.from_now }

          it_behaves_like 'invalid dates raise PG exclusion error'
        end

        context 'when due_date overlaps' do
          let(:start_date) { Date.today }
          let(:due_date) { 6.days.from_now }

          it_behaves_like 'invalid dates raise PG exclusion error'
        end

        context 'when both overlap' do
          let(:start_date) { 5.days.from_now }
          let(:due_date) { 6.days.from_now }

          it_behaves_like 'invalid dates raise PG exclusion error'
        end
      end

      context 'with valid dates' do
        let!(:iteration2) { create(:iteration, :with_due_date, iterations_cadence: iterations_cadence, start_date: iteration1.due_date + 1.day) }

        it 'can be updated in bulk without triggering the exclusion violation' do
          dates1 = { start_date: iteration1.start_date, due_date: iteration1.due_date }
          dates2 = { start_date: iteration2.start_date, due_date: iteration2.due_date }

          expect do
            iterations_cadence.transaction do
              iteration1.update_columns(dates2)
              iteration2.update_columns(dates1)
            end
          end.not_to raise_exception
        end
      end
    end
  end

  describe 'callbacks', :aggregate_failures do
    let_it_be(:group) { create(:group) }
    let_it_be(:iteration_cadence) { create(:iterations_cadence, group: group) }

    shared_examples 'sequence numbers are correctly updated' do
      it 'triggers sequence number updates' do
        expect(ordered_iterations.map(&:id)).to eq(expected_iteration_order)
        expect(ordered_iterations.map(&:sequence)).to eq(expected_sequence)
      end
    end

    describe 'after_save :update_iteration_sequences' do
      context 'when start_date or due_date is not changed after save' do
        let!(:iteration) { create(:iteration, iterations_cadence: iteration_cadence, start_date: Date.today, due_date: Date.today + 2.days) }

        it 'the callback is not triggered' do
          expect(iteration).not_to receive(:update_iteration_sequences)

          iteration.update!(description: "foobar")
        end
      end

      it 'updates a new iteration with a correct iteration sequence number' do
        expect(create(:iteration).sequence).to eq(1)
      end

      context 'when iterations exist in the cadence' do
        let_it_be(:iteration1) { create(:iteration, :with_due_date, iterations_cadence: iteration_cadence, start_date: 1.week.from_now) }
        let_it_be(:iteration2) { create(:iteration, :with_due_date, iterations_cadence: iteration_cadence, start_date: 3.weeks.from_now) }

        context 'creating' do
          let(:new_iteration) { build(:iteration, :with_due_date, iterations_cadence: iteration_cadence, start_date: new_start_date ) }

          before do
            new_iteration.save!
          end

          where(:new_start_date, :expected_iteration_order) do
            1.week.ago | lazy { [new_iteration.id, iteration1.id, iteration2.id] }
            Date.today       | lazy { [new_iteration.id, iteration1.id, iteration2.id] }
            2.weeks.from_now | lazy { [iteration1.id, new_iteration.id, iteration2.id] }
            4.weeks.from_now | lazy { [iteration1.id, iteration2.id, new_iteration.id] }
          end

          with_them do
            it_behaves_like 'sequence numbers are correctly updated'
          end
        end

        context 'updating' do
          let!(:target_iteration) { create(:iteration, :with_due_date, iterations_cadence: iteration_cadence, start_date: start_date ) }

          before do
            target_iteration.update!(start_date: new_start_date, due_date: new_start_date + 4.days)
          end

          where(:start_date, :new_start_date, :expected_iteration_order) do
            4.weeks.from_now | 1.week.ago | lazy { [target_iteration.id, iteration1.id, iteration2.id] }
            2.weeks.from_now | Date.today | lazy { [target_iteration.id, iteration1.id, iteration2.id] }
            Date.today       | 2.weeks.from_now | lazy { [iteration1.id, target_iteration.id, iteration2.id] }
            1.week.ago       | 4.weeks.from_now | lazy { [iteration1.id, iteration2.id, target_iteration.id] }
          end

          with_them do
            it_behaves_like 'sequence numbers are correctly updated'
          end
        end
      end
    end

    describe 'after_destroy :update_iteration_sequences' do
      let!(:iteration1) { create(:iteration, :with_due_date, iterations_cadence: iteration_cadence, start_date: 1.week.ago) }
      let!(:iteration2) { create(:iteration, :with_due_date, iterations_cadence: iteration_cadence, start_date: 2.weeks.from_now) }
      let!(:iteration3) { create(:iteration, :with_due_date, iterations_cadence: iteration_cadence, start_date: 4.weeks.from_now) }

      before do
        iteration_to_destroy.destroy!
      end

      context 'destroying a past iteration' do
        let(:iteration_to_destroy) { iteration1 }
        let(:expected_iteration_order) { [iteration2.id, iteration3.id] }

        it_behaves_like 'sequence numbers are correctly updated'
      end

      context 'destroying an upcoming iteration' do
        let(:iteration_to_destroy) { iteration3 }
        let(:expected_iteration_order) { [iteration1.id, iteration2.id] }

        it_behaves_like 'sequence numbers are correctly updated'
      end
    end

    describe 'before_destroy :check_if_can_be_destroyed' do
      let!(:iteration1) { create(:iteration, iterations_cadence: iteration_cadence, start_date: 1.week.ago, due_date: 1.week.ago + 4.days) }
      let!(:iteration2) { create(:iteration, iterations_cadence: iteration_cadence, start_date: Date.today, due_date: Date.today + 4.days) }

      context 'current iteration is the last iteration in a cadence' do
        it 'destroys the current iteration' do
          expect { iteration2.destroy! }.to change { iteration_cadence.iterations.count }.by(-1)
        end
      end

      context 'current iteration is not the last iteration in a cadence' do
        let_it_be(:iteration3) { create(:iteration, iterations_cadence: iteration_cadence, start_date: 1.week.from_now, due_date: 1.week.from_now + 4.days) }

        it 'throws an error when attempting to destroy the current iteration' do
          expect { iteration2.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
        end
      end

      context 'upcoming iteration' do
        let_it_be(:iteration3) { create(:iteration, iterations_cadence: iteration_cadence, start_date: 1.week.from_now, due_date: 1.week.from_now + 4.days) }
        let_it_be(:iteration4) { create(:iteration, iterations_cadence: iteration_cadence, start_date: 2.weeks.from_now, due_date: 2.weeks.from_now + 4.days) }

        it 'throws an error when attempting to destroy an upcoming iteration that is not the last iteration in a cadence' do
          expect { iteration3.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
        end

        it 'destroys an upcoming iteration when it is the last iteration in a cadence' do
          expect { iteration4.destroy! }.to change { iteration_cadence.iterations.count }.by(-1)
        end
      end
    end
  end

  context 'search and sorting scopes' do
    let_it_be(:group1) { create(:group) }
    let_it_be(:group2) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group1) }
    let_it_be(:plan_cadence) { create(:iterations_cadence, title: 'plan cadence', group: group1) }
    let_it_be(:product_cadence) { create(:iterations_cadence, title: 'product management', group: subgroup) }
    let_it_be(:cadence) { create(:iterations_cadence, title: 'cadence', group: group2) }
    let_it_be(:plan_iteration1) { create(:iteration, :with_due_date, title: "Iteration 1", iterations_cadence: plan_cadence, start_date: 1.week.ago) }
    let_it_be(:plan_iteration2) { create(:iteration, :with_due_date, title: "My iteration", iterations_cadence: plan_cadence, start_date: 2.weeks.ago) }
    let_it_be(:product_iteration) { create(:iteration, :with_due_date, title: "Iteration 2", iterations_cadence: product_cadence, start_date: 1.week.from_now) }
    let_it_be(:cadence_iteration) { create(:iteration, :with_due_date, iterations_cadence: cadence, start_date: Date.today) }

    shared_examples "search returns correct records" do
      it { is_expected.to contain_exactly(*expected_iterations) }
    end

    describe '.search_title' do
      where(:query, :expected_iterations) do
        'iter 1'         | lazy { [plan_iteration1] }
        'iteration'      | lazy { [plan_iteration1, plan_iteration2, product_iteration] }
        'iteration 1'    | lazy { [plan_iteration1] }
        'my iteration 1' | lazy { [] }
      end

      with_them do
        subject { described_class.search_title(query) }

        it_behaves_like "search returns correct records"
      end
    end

    describe '.search_cadence_title' do
      where(:query, :expected_iterations) do
        'plan'            | lazy { [plan_iteration1, plan_iteration2] }
        'plan cadence'    | lazy { [plan_iteration1, plan_iteration2] }
        'product cadence' | lazy { [] }
        'cadence'         | lazy { [plan_iteration1, plan_iteration2, cadence_iteration] }
      end

      with_them do
        subject { described_class.search_cadence_title(query) }

        it_behaves_like "search returns correct records"
      end
    end

    describe '.search_title_or_cadence_title' do
      where(:query, :expected_iterations) do
        # The same test cases used for .search_title
        'iter 1'          | lazy { [plan_iteration1] }
        'iteration'       | lazy { [plan_iteration1, plan_iteration2, product_iteration] }
        'iteration 1'     | lazy { [plan_iteration1] }
        'my iteration 1'  | lazy { [] }
        # The same test cases used for .search_cadence_title
        'plan'            | lazy { [plan_iteration1, plan_iteration2] }
        'plan cadence'    | lazy { [plan_iteration1, plan_iteration2] }
        'product cadence' | lazy { [] }
        'cadence'         | lazy { [plan_iteration1, plan_iteration2, cadence_iteration] }
        # At least one of cadence title or iteration title should contain all of the terms
        'plan iteration'  | lazy { [] }
      end

      with_them do
        subject { described_class.search_title_or_cadence_title(query) }

        it_behaves_like "search returns correct records"
      end
    end

    describe '.sort_by_cadence_id_and_due_date_asc' do
      subject { described_class.all.sort_by_cadence_id_and_due_date_asc }

      it { is_expected.to eq([plan_iteration2, plan_iteration1, product_iteration, cadence_iteration]) }
    end
  end

  context 'time scopes' do
    let_it_be(:cadence) { create(:iterations_cadence, group: create(:group)) }
    let_it_be(:iteration_1) { create(:iteration, :skip_future_date_validation, iterations_cadence: cadence, start_date: 3.days.ago, due_date: 1.day.from_now) }
    let_it_be(:iteration_2) { create(:iteration, :skip_future_date_validation, iterations_cadence: cadence, start_date: 10.days.ago, due_date: 4.days.ago) }
    let_it_be(:iteration_3) { create(:iteration, iterations_cadence: cadence, start_date: 4.days.from_now, due_date: 1.week.from_now) }

    describe 'start_date_passed' do
      it 'returns iterations where start_date is in the past but due_date is in the future' do
        expect(described_class.start_date_passed).to contain_exactly(iteration_1)
      end
    end

    describe 'due_date_passed' do
      it 'returns iterations where due date is in the past' do
        expect(described_class.due_date_passed).to contain_exactly(iteration_2)
      end
    end
  end

  describe '#validate_group' do
    let_it_be(:group) { create(:group) }
    let_it_be(:iterations_cadence) { create(:iterations_cadence, group: group) }

    context 'when the iteration and iteration cadence groups are same' do
      it 'is valid' do
        iteration = build(:iteration, group: group, iterations_cadence: iterations_cadence)

        expect(iteration).to be_valid
      end
    end

    context 'when the iteration and iteration cadence groups are different' do
      it 'is invalid' do
        other_group = create(:group)
        iteration = build(:iteration, group: other_group, iterations_cadence: iterations_cadence)

        expect(iteration).not_to be_valid
      end
    end
  end

  describe '.within_timeframe' do
    let_it_be(:group) { create(:group) }
    let_it_be(:cadence) { create(:iterations_cadence, group: group) }
    let_it_be(:now) { Time.current }
    let_it_be(:iteration_1) { create(:iteration, iterations_cadence: cadence, start_date: now, due_date: 1.day.from_now) }
    let_it_be(:iteration_2) { create(:iteration, iterations_cadence: cadence, start_date: 2.days.from_now, due_date: 3.days.from_now) }
    let_it_be(:iteration_3) { create(:iteration, iterations_cadence: cadence, start_date: 4.days.from_now, due_date: 1.week.from_now) }

    it 'returns iterations with start_date and/or end_date between timeframe' do
      iterations = described_class.within_timeframe(2.days.from_now, 3.days.from_now)

      expect(iterations).to match_array([iteration_2])
    end

    it 'returns iterations which starts before the timeframe' do
      iterations = described_class.within_timeframe(1.day.from_now, 3.days.from_now)

      expect(iterations).to match_array([iteration_1, iteration_2])
    end

    it 'returns iterations which ends after the timeframe' do
      iterations = described_class.within_timeframe(3.days.from_now, 5.days.from_now)

      expect(iterations).to match_array([iteration_2, iteration_3])
    end
  end

  describe '.by_iteration_cadence_ids' do
    let_it_be(:group) { create(:group) }
    let_it_be(:iteration_cadence) { create(:iterations_cadence, group: group) }
    let_it_be(:iterations_cadence1) { create(:iterations_cadence, group: group, start_date: 6.days.ago) }
    let_it_be(:iterations_cadence2) { create(:iterations_cadence, group: group, start_date: 6.days.ago) }
    let_it_be(:closed_iteration) { create(:iteration, :closed, :skip_future_date_validation, iterations_cadence: iterations_cadence1, group: group, start_date: 8.days.ago, due_date: 2.days.ago) }
    let_it_be(:current_iteration) { create(:iteration, :current, :skip_future_date_validation, iterations_cadence: iterations_cadence2, group: group, start_date: 1.day.ago, due_date: 6.days.from_now) }
    let_it_be(:upcoming_iteration) { create(:iteration, :upcoming, iterations_cadence: iterations_cadence2, group: group, start_date: 1.week.from_now, due_date: 2.weeks.from_now) }

    it 'returns iterations by cadence' do
      iterations = described_class.by_iteration_cadence_ids(iterations_cadence1)

      expect(iterations).to match_array([closed_iteration])
    end

    it 'returns iterations by multiple cadences' do
      iterations = described_class.by_iteration_cadence_ids([iterations_cadence1, iterations_cadence2])

      expect(iterations).to match_array([closed_iteration, current_iteration, upcoming_iteration])
    end
  end

  context 'sets correct state based on iteration dates' do
    around do |example|
      travel_to(Time.utc(2019, 12, 30)) { example.run }
    end

    let_it_be(:group) { create(:group) }
    let_it_be(:iterations_cadence) { create(:iterations_cadence, group: group, start_date: 6.days.ago) }

    let(:iteration) { build(:iteration, group: iterations_cadence.group, iterations_cadence: iterations_cadence, start_date: start_date, due_date: 2.weeks.after(start_date).to_date) }

    context 'start_date is in the future' do
      let(:start_date) { 1.day.from_now.utc.to_date }

      it 'sets state to started' do
        iteration.save!

        expect(iteration.state).to eq('upcoming')
      end
    end

    context 'start_date is today' do
      let(:start_date) { Time.now.utc.to_date }

      it 'sets state to started' do
        iteration.save!

        expect(iteration.state).to eq('current')
      end
    end

    context 'start_date is in the past and due date is still in the future' do
      let(:start_date) { 1.week.ago.utc.to_date }

      it 'sets state to started' do
        iteration.save!

        expect(iteration.state).to eq('current')
      end
    end

    context 'start_date is in the past and due date is also in the past' do
      let(:start_date) { 3.weeks.ago.utc.to_date }

      it 'sets state to started' do
        iteration.save!

        expect(iteration.state).to eq('closed')
      end
    end

    context 'when dates for an existing iteration change' do
      context 'when iteration dates go from future to past' do
        let(:iteration) { create(:iteration, iterations_cadence: iterations_cadence, start_date: 2.weeks.from_now.utc.to_date, due_date: 3.weeks.from_now.utc.to_date) }

        it 'sets state to closed' do
          expect(iteration.state).to eq('upcoming')

          iteration.start_date -= 4.weeks
          iteration.due_date -= 4.weeks
          iteration.save!

          expect(iteration.state).to eq('closed')
        end
      end

      context 'when iteration dates go from past to future' do
        let(:iteration) { create(:iteration, iterations_cadence: iterations_cadence, start_date: 2.weeks.ago.utc.to_date, due_date: 1.week.ago.utc.to_date) }

        it 'sets state to upcoming' do
          expect(iteration.state).to eq('closed')

          iteration.start_date += 3.weeks
          iteration.due_date += 3.weeks
          iteration.save!

          expect(iteration.state).to eq('upcoming')
        end

        context 'and today is between iteration start and due dates' do
          it 'sets state to started' do
            expect(iteration.state).to eq('closed')

            iteration.start_date += 2.weeks
            iteration.due_date += 2.weeks
            iteration.save!

            expect(iteration.state).to eq('current')
          end
        end
      end
    end
  end

  it_behaves_like 'a timebox', :iteration do
    let_it_be(:group) { create(:group) }
    let_it_be(:iteration_cadence) { create(:iterations_cadence, group: group) }

    let(:cadence) { create(:iterations_cadence, group: group) }
    let(:timebox) { create(:iteration, iterations_cadence: cadence) }
    let(:timebox_table_name) { described_class.table_name.to_sym }

    # Overrides used during .within_timeframe
    let(:mid_point) { 1.year.from_now.to_date }
    let(:open_on_left) { min_date - 100.days }
    let(:open_on_right) { max_date + 100.days }
  end

  context 'when closing iteration' do
    let_it_be(:group) { create(:group) }
    let_it_be(:iteration_cadence) { create(:iterations_cadence, group: group) }
    let_it_be_with_reload(:iteration) { create(:iteration, iterations_cadence: iteration_cadence, start_date: 4.days.from_now, due_date: 1.week.from_now) }

    context 'when cadence roll-over flag enabled' do
      before do
        iteration.iterations_cadence.update!(automatic: true, active: true, roll_over: true)
      end

      it 'triggers roll-over issues worker' do
        expect(Iterations::RollOverIssuesWorker).to receive(:perform_async).with([iteration.id])

        iteration.close!
      end
    end

    context 'when cadence roll-over flag disabled' do
      before do
        iteration.iterations_cadence.update!(automatic: true, active: true, roll_over: false)
      end

      it 'triggers roll-over issues worker' do
        expect(Iterations::RollOverIssuesWorker).not_to receive(:perform_async)

        iteration.close!
      end
    end
  end
end
