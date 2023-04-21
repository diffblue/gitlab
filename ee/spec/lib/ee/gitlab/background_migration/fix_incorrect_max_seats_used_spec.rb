# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::FixIncorrectMaxSeatsUsed, :saas do
  describe '#perform' do
    subject(:migration) { described_class.new }

    let!(:namespaces) { table(:namespaces) }
    let!(:plans) { table(:plans) }

    let(:seats) { 2 }
    let(:seats_in_use) { 5 }
    let(:max_seats_used) { 10 }
    let(:seats_owed) { [0, max_seats_used - seats].max }

    let(:start_date) { Date.parse('2021-11-10') }
    let(:end_date) { start_date + 1.year }

    let(:keep_old_seats_attributes_after_renew) { true }

    let(:logger) { instance_spy(Gitlab::BackgroundMigration::FixIncorrectMaxSeatsUsed::FixIncorrectMaxSeatsUsedJsonLogger) }

    let!(:gitlab_subscription) { generate_gitlab_subscription }

    def perform_and_reload
      migration.perform

      gitlab_subscription.reload
    end

    def generate_gitlab_subscription
      initial_start_date = start_date - renewed_count.years
      initial_end_date = initial_start_date + 1.year

      namespace = namespaces.create!(name: 'gitlab', path: 'gitlab-org', type: 'Group')
      plan = plans.create!(name: 'gold')
      gs = Gitlab::BackgroundMigration::FixIncorrectMaxSeatsUsed::GitlabSubscription.create!(
        namespace_id: namespace.id,
        seats: seats,
        seats_in_use: seats_in_use,
        max_seats_used: max_seats_used,
        seats_owed: seats_owed,
        start_date: initial_start_date,
        end_date: initial_end_date,
        hosted_plan_id: plan.id)

      renewed_count.downto(1) do |i|
        old_seats_attributes = { seats: gs.seats, max_seats_used: gs.max_seats_used, seats_owed: gs.seats_owed, seats_in_use: gs.seats_in_use }

        renewed_start_date = gs.end_date
        renewed_end_date = renewed_start_date + 1.year

        gs.update!(start_date: renewed_start_date, end_date: renewed_end_date)
        gs.update_columns(old_seats_attributes) if keep_old_seats_attributes_after_renew
      end

      gs.reload
    end

    shared_examples 'does not reset max_seats_used and seats_owed' do
      it 'does not reset max_seats_used and seats_owed', migration: false do
        expect do
          perform_and_reload
        end.to not_change(gitlab_subscription, :max_seats_used)
          .and not_change(gitlab_subscription, :seats_owed)
          .and not_change(GitlabSubscriptionHistory, :count)
      end
    end

    shared_examples 'resets max_seats_used and seats_owed' do
      it 'resets max_seats_used and seats_owed', migration: false do
        gs_before_reset = gitlab_subscription.clone

        expect(Gitlab::BackgroundMigration::FixIncorrectMaxSeatsUsed::FixIncorrectMaxSeatsUsedJsonLogger).to receive(:build).and_return(logger)

        expect do
          perform_and_reload
        end.to change(gitlab_subscription, :max_seats_used).from(10).to(5)
          .and change(gitlab_subscription, :seats_owed).from(8).to(3)
          .and change(GitlabSubscriptionHistory, :count).by(1)

        expect(logger).to have_received(:info).with(
          hash_including(
            identified_subscription: gs_before_reset.attributes.merge(namespace_path: gs_before_reset.namespace.path),
            changes: hash_including(max_seats_used: [10, 5], seats_owed: [8, 3]),
            success: true))
      end
    end

    shared_examples 'gitlab subscription has one or more renew history' do
      include_examples 'resets max_seats_used and seats_owed'

      context 'when max_seats_used has already been correctly reset during renew' do
        let(:keep_old_seats_attributes_after_renew) { false }

        include_examples 'does not reset max_seats_used and seats_owed'
      end

      context 'when start_date is before 2021-08-02' do
        let(:start_date) { Date.parse('2021-08-01') }

        include_examples 'does not reset max_seats_used and seats_owed'
      end

      context 'when start_date is 2021-08-02' do
        let(:start_date) { Date.parse('2021-08-02') }

        include_examples 'resets max_seats_used and seats_owed'
      end

      context 'when start_date is 2021-11-20' do
        let(:start_date) { Date.parse('2021-11-20') }

        include_examples 'resets max_seats_used and seats_owed'
      end

      context 'when start_date is after 2021-11-20' do
        let(:start_date) { Date.parse('2021-11-21') }

        include_examples 'does not reset max_seats_used and seats_owed'
      end

      context 'when batch_2_for_start_date_before_02_aug_2021' do
        def perform_and_reload
          migration.perform(batch)

          gitlab_subscription.reload
        end

        let(:batch) { 'batch_2_for_start_date_before_02_aug_2021' }

        context 'when start_date is before 2021-08-02' do
          let(:start_date) { Date.parse('2021-08-01') }

          include_examples 'resets max_seats_used and seats_owed'
        end

        context 'when start_date is 2021-08-02' do
          let(:start_date) { Date.parse('2021-08-02') }

          include_examples 'does not reset max_seats_used and seats_owed'
        end

        context 'when start_date is after 2021-08-02' do
          let(:start_date) { Date.parse('2021-08-03') }

          include_examples 'does not reset max_seats_used and seats_owed'
        end
      end

      context 'when max_seats_used is 0' do
        let(:max_seats_used) { 0 }

        include_examples 'does not reset max_seats_used and seats_owed'
      end

      context 'when max_seats_used equals to seats_in_use' do
        let(:max_seats_used) { seats_in_use }

        include_examples 'does not reset max_seats_used and seats_owed'
      end

      context 'when max_seats_used is less than seats_in_use' do
        let(:max_seats_used) { seats_in_use - 1 }

        include_examples 'does not reset max_seats_used and seats_owed'
      end

      context 'when max_seats_used equals to seats' do
        let(:max_seats_used) { seats }

        include_examples 'does not reset max_seats_used and seats_owed'
      end

      context 'when max_seats_used is less than seats' do
        let(:max_seats_used) { seats - 1 }

        include_examples 'does not reset max_seats_used and seats_owed'
      end

      context 'when max_seats_used increases after renew' do
        before do
          gitlab_subscription.update_columns(max_seats_used: max_seats_used + 1)
        end

        include_examples 'does not reset max_seats_used and seats_owed'
      end

      context 'when seats_in_use increased to max_seats_used' do
        before do
          gitlab_subscription.update_columns(seats_in_use: max_seats_used)
        end

        include_examples 'does not reset max_seats_used and seats_owed'
      end

      context 'when seats_in_use increased to greater than max_seats_used' do
        before do
          gitlab_subscription.update_columns(seats_in_use: max_seats_used + 1)
        end

        include_examples 'does not reset max_seats_used and seats_owed'
      end
    end

    context 'when gitlab subscription does not have renew history' do
      let(:renewed_count) { 0 }

      include_examples 'does not reset max_seats_used and seats_owed'
    end

    context 'when gitlab subscription has one renew history' do
      let(:renewed_count) { 1 }

      it_behaves_like 'gitlab subscription has one or more renew history'
    end

    context 'gitlab subscription has more than one renew histories' do
      let(:renewed_count) { 2 }

      it_behaves_like 'gitlab subscription has one or more renew history'
    end

    context 'when gitlab subscription has non-renewal update history' do
      before do
        gitlab_subscription.update!(auto_renew: !gitlab_subscription.auto_renew)
        gitlab_subscription.reload
      end

      context 'when gitlab subscription does not have renew history' do
        let(:renewed_count) { 0 }

        include_examples 'does not reset max_seats_used and seats_owed'
      end

      context 'when gitlab subscription has one renew history' do
        let(:renewed_count) { 1 }

        it_behaves_like 'gitlab subscription has one or more renew history'
      end

      context 'gitlab subscription has more than one renew histories' do
        let(:renewed_count) { 2 }

        it_behaves_like 'gitlab subscription has one or more renew history'
      end
    end
  end
end

RSpec.describe Gitlab::BackgroundMigration::FixIncorrectMaxSeatsUsed::FixIncorrectMaxSeatsUsedJsonLogger do
  subject { described_class.new('/dev/null') }

  let(:hash_message) { { 'message' => 'Message', 'project_id' => '123' } }
  let(:string_message) { 'Information' }

  it 'logs a hash as a JSON', migration: false do
    expect(Gitlab::Json.parse(subject.format_message('INFO', Time.current, nil, hash_message))).to include(hash_message)
  end

  it 'logs a string as a JSON', migration: false do
    expect(Gitlab::Json.parse(subject.format_message('INFO', Time.current, nil, string_message))).to include('message' => string_message)
  end

  it 'logs into the expected file', migration: false do
    expect(described_class.file_name).to eq('fix_incorrect_max_seats_used_json.log')
  end
end
