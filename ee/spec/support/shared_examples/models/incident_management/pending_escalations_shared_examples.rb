# frozen_string_literal: true

RSpec.shared_examples 'IncidentManagement::PendingEscalation model' do
  let_it_be(:escalatable_type) { described_class.name.demodulize.downcase.to_sym }
  let_it_be(:pending_escalation) { create_escalation }

  subject { pending_escalation }

  it { is_expected.to be_valid }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:process_at) }
    it { is_expected.to validate_presence_of(:rule_id) }
    it { is_expected.to delegate_method(:project).to(escalatable_type) }
    it { is_expected.to validate_uniqueness_of(:rule_id).scoped_to([:"#{escalatable_type}_id"]) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(escalatable_type) }
    it { is_expected.to belong_to(:rule) }
  end

  describe 'scopes' do
    context 'with escalations scheduled for various times' do
      let_it_be(:policy) { create(:incident_management_escalation_policy) }
      let_it_be(:rule) { policy.rules.first }

      let_it_be(:two_months_ago_escalation) { create_escalation(rule: rule, process_at: 2.months.ago) }
      let_it_be(:three_weeks_ago_escalation) { create_escalation(rule: rule, process_at: 3.weeks.ago) }
      let_it_be(:three_days_ago_escalation) { create_escalation(rule: rule, process_at: 3.days.ago) }
      let_it_be(:upcoming_escalation) { create_escalation(rule: rule, process_at: 5.minutes.from_now) }
      let_it_be(:future_escalation) { create_escalation(rule: rule, process_at: 3.days.from_now) }

      let_it_be(:escalations) { described_class.where(rule: rule) }

      describe '.processable' do
        subject { escalations.processable }

        it { is_expected.to match_array [three_weeks_ago_escalation, three_days_ago_escalation] }
      end

      describe '.upcoming' do
        subject { escalations.upcoming }

        it { is_expected.to match_array [three_weeks_ago_escalation, three_days_ago_escalation, upcoming_escalation] }
      end
    end

    describe '.for_target' do
      let_it_be(:other_escalation) { create_escalation }

      subject { described_class.for_target(other_escalation.target) }

      it { is_expected.to contain_exactly(other_escalation) }
    end
  end

  describe '.delete_by_target' do
    let_it_be(:removeable_escalation) { create_escalation }

    subject { described_class.delete_by_target(removeable_escalation.target) }

    it 'removes the escalations for the provided target(s)' do
      expect { subject }.to change(described_class, :count).by(-1)
      expect { removeable_escalation.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  private

  def create_escalation(type: escalatable_type, **options)
    create(
      :"incident_management_pending_#{type}_escalation",
      **options
    )
  end
end
