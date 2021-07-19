# frozen_string_literal: true

require "spec_helper"

RSpec.describe License do
  using RSpec::Parameterized::TableSyntax

  subject(:license) { build(:license, data: gl_license.export) }

  let(:gl_license) { build(:gitlab_license) }

  describe 'validations' do
    describe '#valid_license' do
      context 'when the license is provided' do
        it { is_expected.to be_valid }
      end

      context 'when no license is provided' do
        before do
          license.data = nil
        end

        it { is_expected.not_to be_valid }
      end
    end

    describe '#check_trueup' do
      let(:active_user_count) { described_class.current.daily_billable_users_count + 10 }
      let(:date)              { described_class.current.starts_at }

      before do
        create(:historical_data, recorded_at: date, active_user_count: active_user_count)
      end

      context 'when reconciliation_completed is true on the license' do
        before do
          set_restrictions(restricted_user_count: 10, trueup_quantity: 8, reconciliation_completed: true)
        end

        it { is_expected.to be_valid }
      end

      context 'when reconciliation_completed is false on the license' do
        it 'adds errors for invalid true up figures' do
          set_restrictions(restricted_user_count: 10, trueup_quantity: 8, reconciliation_completed: false)

          expect(license).not_to be_valid
          expect(license.errors.full_messages.to_sentence)
            .to include 'You have applied a True-up for 8 users but you need one for 10 users'
        end
      end

      context 'when reconciliation_completed is not present on the license' do
        it 'adds errors for invalid true up figures' do
          set_restrictions(restricted_user_count: 10, trueup_quantity: 8)

          expect(license).not_to be_valid
          expect(license.errors.full_messages.to_sentence)
            .to include 'You have applied a True-up for 8 users but you need one for 10 users'
        end
      end

      context 'when quantity is ok' do
        before do
          set_restrictions(restricted_user_count: 5, trueup_quantity: 10)
        end

        it { is_expected.to be_valid }

        context 'but active users exceeds restricted user count' do
          before do
            create_list(:user, 6)
          end

          it { is_expected.not_to be_valid }
        end
      end

      context 'when quantity is wrong' do
        before do
          set_restrictions(restricted_user_count: 5, trueup_quantity: 8)
        end

        it { is_expected.not_to be_valid }
      end

      context 'when previous user count is not present' do
        before do
          set_restrictions(restricted_user_count: 5, trueup_quantity: 7)
        end

        it 'uses current active user count to calculate the expected true-up' do
          create_list(:user, 3)

          expect(license).to be_valid
        end

        context 'with wrong true-up quantity' do
          before do
            create_list(:user, 2)
          end

          it { is_expected.not_to be_valid }
        end
      end

      context 'when previous user count is present' do
        before do
          set_restrictions(restricted_user_count: 5, trueup_quantity: 6, previous_user_count: 4)
        end

        it { is_expected.to be_valid }
      end
    end

    describe '#check_restricted_user_count' do
      context 'when reconciliation_completed is true' do
        context 'when restricted_user_count is equal or more than active_user_count' do
          before do
            set_restrictions(restricted_user_count: 10, reconciliation_completed: true)
          end

          it { is_expected.to be_valid }
        end

        context 'when the restricted_user_count is less than active_user_count' do
          before do
            set_restrictions(restricted_user_count: 2, reconciliation_completed: true)
            create_list(:user, 6)
            create(:historical_data, recorded_at: described_class.current.starts_at, active_user_count: 100)
          end

          it 'add limit error' do
            expect(license.valid?).to be_falsey

            expect(license.errors.full_messages.to_sentence).to include(
              'This GitLab installation currently has 6 active users, exceeding this license\'s limit of 2 by 4 users'
            )
            expect(license.errors.full_messages.to_sentence).not_to include(
              'During the year before this license started'
            )
          end
        end
      end

      context 'when reconciliation_completed is false' do
        context 'when the restricted_user_count is less than active_user_count' do
          before do
            set_restrictions(restricted_user_count: 2, reconciliation_completed: false)
            create_list(:user, 6)
            create(:historical_data, recorded_at: described_class.current.starts_at, active_user_count: 100)
          end

          it 'add limit error' do
            expect(license.valid?).to be_falsey

            expect(license.errors.full_messages.to_sentence).to include(
              'During the year before this license started'
            )
          end
        end
      end
    end

    describe '#check_users_limit' do
      context 'for each plan' do
        before do
          create(:group_member, :guest)
          create(:group_member, :reporter)
          create(:license, plan: plan)
        end

        let(:users_count) { nil }
        let(:new_license) do
          gl_license = build(:gitlab_license, restrictions: { plan: plan, active_user_count: users_count, previous_user_count: 1 })
          build(:license, data: gl_license.export)
        end

        where(:gl_plan, :valid) do
          ::License::STARTER_PLAN  | false
          ::License::PREMIUM_PLAN  | false
          ::License::ULTIMATE_PLAN | true
        end

        with_them do
          let(:plan) { gl_plan }

          context 'when license has restricted users' do
            let(:users_count) { 1 }

            it { expect(new_license.valid?).to eq(valid) }
          end

          context 'when license has unlimited users' do
            let(:users_count) { nil }

            it 'is always valid' do
              expect(new_license.valid?).to eq(true)
            end
          end
        end
      end

      context 'threshold for users overage' do
        let(:current_active_users_count) { 0 }
        let(:new_license) { build(:license, data: gitlab_license.export) }
        let(:gitlab_license) do
          build(
            :gitlab_license,
            starts_at: Date.current,
            restrictions: { active_user_count: 10, previous_user_count: previous_user_count }
          )
        end

        context 'when current active users count is above the limit set by the license' do
          before do
            create_list(:user, current_active_users_count)
            HistoricalData.track!
          end

          context 'when license is from a fresh subscription' do
            let(:previous_user_count) { nil }

            context 'when current active users count is under the threshold' do
              let(:current_active_users_count) { 11 }

              it 'accepts the license' do
                expect(new_license).to be_valid
              end
            end

            context 'when current active users count is above the threshold' do
              let(:current_active_users_count) { 12 }

              it 'does not accept the license' do
                expect(new_license).not_to be_valid
              end

              context 'when license is a cloud license' do
                let(:gitlab_license) do
                  build(
                    :gitlab_license,
                    cloud_licensing_enabled: true,
                    starts_at: Date.current,
                    restrictions: { active_user_count: 10, previous_user_count: previous_user_count }
                  )
                end

                it 'accepts the license' do
                  expect(new_license).to be_valid
                end
              end
            end
          end

          context 'when license is from a renewal' do
            let(:previous_user_count) { 1 }

            context 'when current active users count is under the threshold' do
              let(:current_active_users_count) { 11 }

              it 'does not accept the license' do
                expect(new_license).not_to be_valid
              end
            end
          end
        end
      end

      describe 'Historical active user count' do
        let(:active_user_count) { described_class.current.daily_billable_users_count + 10 }
        let(:date)              { described_class.current.starts_at }
        let!(:historical_data)  { create(:historical_data, recorded_at: date, active_user_count: active_user_count) }

        context 'when there is no active user count restriction' do
          it { is_expected.to be_valid }
        end

        context 'without historical data' do
          before do
            create_list(:user, 2)

            gl_license.restrictions = {
              previous_user_count: 1,
              active_user_count: described_class.current.daily_billable_users_count - 1
            }

            HistoricalData.delete_all
          end

          context 'with previous_user_count and active users above of license limit' do
            it { is_expected.not_to be_valid }

            it 'shows the proper error message' do
              license.valid?

              error_msg = "This GitLab installation currently has 2 active users, exceeding this license's limit of 1 by 1 user. " \
                        "Please upload a license for at least 2 users or contact sales at https://about.gitlab.com/sales/"

              expect(license.errors[:base].first).to eq(error_msg)
            end
          end
        end

        context 'when the active user count restriction is exceeded' do
          before do
            gl_license.restrictions = { active_user_count: active_user_count - 1 }
          end

          context 'when the license started' do
            it { is_expected.not_to be_valid }
          end

          context 'after the license started' do
            let(:date) { Date.current }

            it { is_expected.to be_valid }
          end

          context 'in the year before the license started' do
            let(:date) { described_class.current.starts_at - 6.months }

            it { is_expected.not_to be_valid }
          end

          context 'earlier than a year before the license started' do
            let(:date) { described_class.current.starts_at - 2.years }

            it { is_expected.to be_valid }
          end
        end

        context 'when the active user count restriction is not exceeded' do
          before do
            gl_license.restrictions = { active_user_count: active_user_count + 1 }
          end

          it { is_expected.to be_valid }
        end

        context 'when the active user count is met exactly' do
          it 'is valid' do
            active_user_count = 100
            gl_license.restrictions = { active_user_count: active_user_count }

            expect(license).to be_valid
          end
        end
      end
    end

    describe '#not_expired' do
      context "when the license doesn't expire" do
        it { is_expected.to be_valid }
      end

      context 'when the license has expired' do
        before do
          gl_license.expires_at = Date.yesterday
        end

        it { is_expected.not_to be_valid }
      end

      context 'when the license has yet to expire' do
        before do
          gl_license.expires_at = Date.tomorrow
        end

        it { is_expected.to be_valid }
      end
    end

    describe 'downgrade' do
      context 'when more users were added in previous period' do
        before do
          create(:historical_data, recorded_at: described_class.current.starts_at - 6.months, active_user_count: 15)

          set_restrictions(restricted_user_count: 5, previous_user_count: 10)
        end

        it 'is invalid without a true-up' do
          expect(license).not_to be_valid
        end
      end

      context 'when no users were added in the previous period' do
        before do
          create(:historical_data, recorded_at: 6.months.ago, active_user_count: 15)

          set_restrictions(restricted_user_count: 10, previous_user_count: 15)
        end

        it { is_expected.to be_valid }
      end
    end
  end

  describe 'Callbacks' do
    describe '#reset_current', :request_store do
      def current_license_cached_value
        License.cache.read(License::CACHE_KEY, License)
      end

      before do
        License.current # Set cache up front
      end

      context 'when a license is created' do
        it 'expires the current_license cached value' do
          expect(current_license_cached_value).to be_present

          create(:license)

          expect(current_license_cached_value).to be_nil
        end
      end

      context 'when a license is updated' do
        it 'expires the current_license cached value' do
          expect(current_license_cached_value).to be_present

          License.last.update!(updated_at: Time.current)

          expect(current_license_cached_value).to be_nil
        end
      end

      context 'when a license is destroyed' do
        it 'expires the current_license cached value' do
          expect(current_license_cached_value).to be_present

          License.last.destroy!

          expect(current_license_cached_value).to be_nil
        end
      end
    end

    describe '#reset_future_dated', :request_store do
      let!(:future_dated_license) { create(:license, data: create(:gitlab_license, starts_at: Date.current + 1.month).export) }

      before do
        described_class.future_dated

        expect(Gitlab::SafeRequestStore.read(:future_dated_license)).to be_present
      end

      context 'when a license is created' do
        it 'deletes the future_dated_license value in Gitlab::SafeRequestStore' do
          create(:license)

          expect(Gitlab::SafeRequestStore.read(:future_dated_license)).to be_nil
        end
      end

      context 'when a license is destroyed' do
        it 'deletes the future_dated_license value in Gitlab::SafeRequestStore' do
          future_dated_license.destroy

          expect(Gitlab::SafeRequestStore.read(:future_dated_license)).to be_nil
        end
      end
    end

    describe '#reset_previous', :request_store do
      let!(:previous_license) do
        create(
          :license,
          data: create(:gitlab_license, starts_at: Date.new(1969, 1, 1), expires_at: Date.new(1969, 12, 31)).export)
      end

      before do
        described_class.previous

        expect(Gitlab::SafeRequestStore.read(:previous_license)).to be_present
      end

      context 'when a license is created' do
        it 'deletes the previous_license value in Gitlab::SafeRequestStore' do
          create(:license)

          expect(Gitlab::SafeRequestStore.read(:previous_license)).to be_nil
        end
      end

      context 'when a license is destroyed' do
        it 'deletes the previous_license value in Gitlab::SafeRequestStore' do
          previous_license.destroy

          expect(Gitlab::SafeRequestStore.read(:previous_license)).to be_nil
        end
      end
    end
  end

  describe 'Scopes' do
    describe '.cloud' do
      it 'includes cloud licenses' do
        create(:license)
        cloud_license_1 = create(:license, cloud: true)
        cloud_license_2 = create(:license, cloud: true)

        result = described_class.cloud

        expect(result).to contain_exactly(cloud_license_1, cloud_license_2)
      end
    end
  end

  describe "Class methods" do
    before do
      described_class.reset_current
    end

    describe '.features_for_plan' do
      it 'returns features for starter plan' do
        expect(described_class.features_for_plan('starter'))
          .to include(:multiple_issue_assignees)
      end

      it 'returns features for premium plan' do
        expect(described_class.features_for_plan('premium'))
          .to include(:multiple_issue_assignees, :cluster_deployments, :file_locks, :group_wikis)
      end

      it 'returns empty array if no features for given plan' do
        expect(described_class.features_for_plan('bronze')).to eq([])
      end
    end

    describe '.plan_includes_feature?' do
      let(:feature) { :cluster_deployments }

      subject { described_class.plan_includes_feature?(plan, feature) }

      context 'when addon included' do
        let(:plan) { 'premium' }

        it { is_expected.to eq(true) }
      end

      context 'when addon not included' do
        let(:plan) { 'starter' }

        it { is_expected.to eq(false) }
      end

      context 'when plan is not set' do
        let(:plan) { nil }

        it { is_expected.to eq(false) }
      end

      context 'when feature does not exists' do
        let(:plan) { 'premium' }
        let(:feature) { nil }

        it { is_expected.to eq(false) }
      end
    end

    describe '.current', :request_store, :use_clean_rails_memory_store_caching do
      context 'when licenses table does not exist' do
        it 'returns nil' do
          allow(described_class).to receive(:table_exists?).and_return(false)

          expect(described_class.current).to be_nil
        end
      end

      context 'when there is no license' do
        it 'returns nil' do
          allow(described_class).to receive(:last_hundred).and_return([])

          expect(described_class.current).to be_nil
        end
      end

      context 'when the license is invalid' do
        it 'returns nil' do
          allow(described_class).to receive(:last_hundred).and_return([license])
          allow(license).to receive(:valid?).and_return(false)

          expect(described_class.current).to be_nil
        end
      end

      context 'when the license is valid' do
        let!(:current_license) { create_list(:license, 2).last }

        it 'returns the license' do
          create(:license, data: create(:gitlab_license, starts_at: Date.current + 1.month).export)

          expect(described_class.current).to eq(current_license)
        end

        it 'caches the license' do
          described_class.reset_current

          expect(described_class).to receive(:load_license).once.and_call_original

          2.times do
            expect(described_class.current).to eq(current_license)
          end

          travel_to(61.seconds.from_now) do
            expect(described_class).to receive(:load_license).once.and_call_original
            expect(described_class.current).to eq(current_license)
          end
        end
      end
    end

    describe '.future_dated' do
      before do
        described_class.reset_future_dated
      end

      context 'when licenses table does not exist' do
        it 'returns nil' do
          allow(described_class).to receive(:table_exists?).and_return(false)

          expect(described_class.future_dated).to be_nil
        end
      end

      context 'when there is no license' do
        it 'returns nil' do
          allow(described_class).to receive(:last_hundred).and_return([])

          expect(described_class.future_dated).to be_nil
        end
      end

      context 'when the license is invalid' do
        it 'returns false' do
          license = build(:license, data: build(:gitlab_license, starts_at: Date.current + 1.month).export)

          allow(described_class).to receive(:last_hundred).and_return([license])
          allow(license).to receive(:valid?).and_return(false)

          expect(described_class.future_dated).to be_nil
        end
      end

      context 'when the license is valid' do
        it 'returns the true' do
          future_dated_license = create(:license, data: create(:gitlab_license, starts_at: Date.current + 1.month).export)

          expect(described_class.future_dated).to eq(future_dated_license)
        end
      end
    end

    describe '.previous' do
      before do
        described_class.reset_previous
      end

      context 'when there is no license' do
        it 'returns nil' do
          allow(described_class).to receive(:last_hundred).and_return([])

          expect(described_class.previous).to be_nil
        end
      end

      context 'when the license is invalid' do
        it 'returns nil' do
          license = build(
            :license,
            data: build(:gitlab_license, starts_at: Date.new(1969, 1, 1), expires_at: Date.new(1969, 12, 31)).export
          )

          allow(described_class).to receive(:last_hundred).and_return([license])
          allow(license).to receive(:valid?).and_return(false)

          expect(described_class.previous).to be_nil
        end
      end

      context 'when the license is valid' do
        context 'when only a current and a future dated license exist' do
          before do
            create(:license, data: create(:gitlab_license, starts_at: Date.current + 1.month).export)
          end

          it 'returns nil' do
            expect(described_class.previous).to be_nil
          end
        end

        context 'when license is not a future dated or the current one' do
          it 'returns the the previous license' do
            previous_license = create(
              :license,
              data: create(:gitlab_license, starts_at: Date.new(2000, 1, 1), expires_at: Date.new(2000, 12, 31)).export
            )
            # create another license since the last uploaded license is considered the current one
            create(
              :license,
              data: create(:gitlab_license, starts_at: Date.new(2001, 1, 1), expires_at: Date.new(2001, 12, 31)).export
            )

            expect(described_class.previous).to eq(previous_license)
          end
        end
      end
    end

    describe ".block_changes?" do
      before do
        allow(License).to receive(:current).and_return(license)
      end

      context "when there is no current license" do
        let(:license) { nil }

        it "returns false" do
          expect(described_class.block_changes?).to be_falsey
        end
      end

      context 'with an expired trial license' do
        let!(:license) { create(:license, trial: true) }

        it 'returns false' do
          expect(described_class.block_changes?).to be_falsey
        end
      end

      context 'with an expired normal license' do
        let!(:license) { create(:license, expired: true) }

        it 'returns true' do
          expect(described_class.block_changes?).to eq(true)
        end
      end

      context "when the current license is set to block changes" do
        before do
          allow(license).to receive(:block_changes?).and_return(true)
        end

        it "returns true" do
          expect(described_class.block_changes?).to be_truthy
        end
      end

      context "when the current license doesn't block changes" do
        it "returns false" do
          expect(described_class.block_changes?).to be_falsey
        end
      end
    end

    describe '.global_feature?' do
      subject { described_class.global_feature?(feature) }

      context 'when it is a global feature' do
        let(:feature) { :geo }

        it { is_expected.to be(true) }
      end

      context 'when it is not a global feature' do
        let(:feature) { :sast }

        it { is_expected.to be(false) }
      end
    end

    describe '.with_valid_license' do
      context 'when license trial' do
        before do
          allow(license).to receive(:trial?).and_return(true)
          allow(License).to receive(:current).and_return(license)
        end

        it 'does not yield block' do
          expect { |b| License.with_valid_license(&b) }.not_to yield_control
        end
      end

      context 'when license nil' do
        before do
          allow(License).to receive(:current).and_return(nil)
        end

        it 'does not yield block' do
          expect { |b| License.with_valid_license(&b) }.not_to yield_control
        end
      end

      context 'when license is valid' do
        before do
          allow(License).to receive(:current).and_return(license)
        end

        it 'yields block' do
          expect { |b| License.with_valid_license(&b) }.to yield_with_args(license)
        end
      end
    end

    describe '.current_cloud_license?' do
      subject { described_class.current_cloud_license?(license_key) }

      let(:license_key) { 'test-key' }

      before do
        allow(License).to receive(:current).and_return(current_license)
      end

      context 'when current license is not set' do
        let(:current_license) { nil }

        it { is_expected.to be(false) }
      end

      context 'when current license is not a cloud license' do
        let(:current_license) { create(:license) }

        it { is_expected.to be(false) }
      end

      context 'when current license is a cloud license but key does not match current' do
        let(:current_license) { create_current_license(cloud_licensing_enabled: true) }

        it { is_expected.to be(false) }
      end

      context 'when current license is a cloud license and key matches current' do
        let(:current_license) { create_current_license(cloud_licensing_enabled: true) }
        let(:license_key) { current_license.data }

        it { is_expected.to be(true) }
      end
    end
  end

  describe "#data_filename" do
    subject { license.data_filename }

    context 'when licensee includes company information' do
      let(:gl_license) do
        build(:gitlab_license, licensee: { 'Company' => ' Example & Partner Inc. 2 ', 'Name' => 'User Example' })
      end

      it { is_expected.to eq('ExamplePartnerInc2.gitlab-license') }
    end

    context 'when licensee does not include company information' do
      let(:gl_license) { build(:gitlab_license, licensee: { 'Name' => 'User Example' }) }

      it { is_expected.to eq('UserExample.gitlab-license') }
    end
  end

  describe "#md5" do
    it "returns the same MD5 for licenses with carriage returns and those without" do
      other_license = build(:license, data: license.data.gsub("\n", "\r\n"))

      expect(other_license.md5).to eq(license.md5)
    end

    it "returns the same MD5 for licenses with trailing newlines and those without" do
      other_license = build(:license, data: license.data.chomp)

      expect(other_license.md5).to eq(license.md5)
    end

    it "returns the same MD5 for licenses with multiple trailing newlines and those with a single trailing newline" do
      other_license = build(:license, data: "#{license.data}\n\n\n")

      expect(other_license.md5).to eq(license.md5)
    end
  end

  describe "#license" do
    context "when no data is provided" do
      before do
        license.data = nil
      end

      it "returns nil" do
        expect(license.license).to be_nil
      end
    end

    context "when corrupt license data is provided" do
      before do
        license.data = "whatever"
      end

      it "returns nil" do
        expect(license.license).to be_nil
      end
    end

    context "when valid license data is provided" do
      it "returns the license" do
        expect(license.license).not_to be_nil
      end
    end
  end

  describe 'reading add-ons' do
    describe '#plan' do
      let(:gl_license) { build(:gitlab_license, restrictions: restrictions.merge(add_ons: {})) }
      let(:license)    { build(:license, data: gl_license.export) }

      subject { license.plan }

      [
        { restrictions: {},                  plan: License::STARTER_PLAN },
        { restrictions: { plan: nil },       plan: License::STARTER_PLAN },
        { restrictions: { plan: '' },        plan: License::STARTER_PLAN },
        { restrictions: { plan: 'unknown' }, plan: 'unknown' }
      ].each do |spec|
        context spec.inspect do
          let(:restrictions) { spec[:restrictions] }

          it { is_expected.to eq(spec[:plan]) }
        end
      end
    end

    describe '#features_from_add_ons' do
      context 'without add-ons' do
        it 'returns an empty array' do
          license = build_license_with_add_ons({}, plan: 'unknown')

          expect(license.features_from_add_ons).to eq([])
        end
      end

      context 'with add-ons' do
        it 'returns all available add-ons' do
          license = build_license_with_add_ons({ 'GitLab_FileLocks' => 2 })

          expect(license.features_from_add_ons).to eq([:file_locks])
        end
      end

      context 'with nil add-ons' do
        it 'returns an empty array' do
          license = build_license_with_add_ons({ 'GitLab_FileLocks' => nil })

          expect(license.features_from_add_ons).to eq([])
        end
      end
    end

    describe '#feature_available?' do
      it 'returns true if add-on exists and have a quantity greater than 0' do
        license = build_license_with_add_ons({ 'GitLab_FileLocks' => 1 })

        expect(license.feature_available?(:file_locks)).to eq(true)
      end

      it 'returns true if the feature is included in the plan do' do
        license = build_license_with_add_ons({}, plan: License::PREMIUM_PLAN)

        expect(license.feature_available?(:auditor_user)).to eq(true)
      end

      it 'returns false if add-on exists but have a quantity of 0' do
        license = build_license_with_add_ons({ 'GitLab_FileLocks' => 0 })

        expect(license.feature_available?(:file_locks)).to eq(false)
      end

      it 'returns false if add-on does not exists' do
        license = build_license_with_add_ons({})

        expect(license.feature_available?(:file_locks)).to eq(false)
      end

      context 'with an expired trial license' do
        let(:license) { create(:license, trial: true, expired: true) }

        before(:all) do
          described_class.delete_all
        end

        ::License::EES_FEATURES.each do |feature|
          it "returns false for #{feature}" do
            expect(license.feature_available?(feature)).to eq(false)
          end
        end
      end
    end

    def build_license_with_add_ons(add_ons, plan: nil)
      gl_license = build(:gitlab_license, restrictions: { add_ons: add_ons, plan: plan })
      build(:license, data: gl_license.export)
    end
  end

  describe '#subscription_id' do
    it 'has correct subscription_id' do
      gl_license = build(:gitlab_license, restrictions: { subscription_id: "1111" })
      license = build(:license, data: gl_license.export)

      expect(license.subscription_id).to eq("1111")
    end
  end

  describe '#daily_billable_users_count' do
    before_all do
      create(:group_member)
      create(:group_member, user: create(:admin))
      create(:group_member, :guest)
      create(:group_member, user: create(:user, :bot))
      create(:group_member, user: create(:user, :project_bot))
      create(:group_member, user: create(:user, :ghost))
      create(:group_member).user.deactivate!
    end

    context 'when license is not for Ultimate plan' do
      it 'includes guests in the count' do
        expect(license.daily_billable_users_count).to eq(3)
      end
    end

    context 'when license is for Ultimate plan' do
      it 'excludes guests in the count' do
        new_license = create(:license, plan: License::ULTIMATE_PLAN)

        expect(new_license.daily_billable_users_count).to eq(2)
      end
    end
  end

  describe '#overage' do
    it 'returns 0 if restricted_user_count is nil' do
      allow(license).to receive(:restricted_user_count) { nil }

      expect(license.overage).to eq(0)
    end

    it 'returns the difference between user_count and restricted_user_count' do
      allow(license).to receive(:restricted_user_count) { 10 }

      expect(license.overage(14)).to eq(4)
    end

    it 'returns the difference using daily_billable_users_count as user_count if no user_count argument provided' do
      allow(license).to receive(:daily_billable_users_count) { 110 }
      allow(license).to receive(:restricted_user_count) { 100 }

      expect(license.overage).to eq(10)
    end

    it 'returns 0 if the difference is a negative number' do
      allow(license).to receive(:restricted_user_count) { 2 }

      expect(license.overage(1)).to eq(0)
    end
  end

  describe '#historical_data' do
    subject(:historical_data_count) { license.historical_data.count }

    let_it_be(:now) { DateTime.new(2014, 12, 15) }
    let_it_be(:license) { create(:license, starts_at: Date.new(2014, 7, 1), expires_at: Date.new(2014, 12, 31)) }

    before_all do
      (1..12).each do |i|
        create(:historical_data, recorded_at: Date.new(2014, i, 1), active_user_count: i * 100)
      end

      create(:historical_data, recorded_at: license.starts_at - 1.day, active_user_count: 1)
      create(:historical_data, recorded_at: license.expires_at + 1.day, active_user_count: 2)
      create(:historical_data, recorded_at: now - 1.year - 1.day, active_user_count: 3)
      create(:historical_data, recorded_at: now + 1.day, active_user_count: 4)
    end

    around do |example|
      travel_to(now) { example.run }
    end

    context 'with using parameters' do
      it 'returns correct number of records within the given range' do
        from = Date.new(2014, 8, 1)
        to = Date.new(2014, 11, 30)

        expect(license.historical_data(from: from, to: to).count).to eq(4)
      end
    end

    context 'with a license that has a start and end date' do
      it 'returns correct number of records within the license range' do
        expect(historical_data_count).to eq(7)
      end
    end

    context 'with a license that has no start date' do
      let_it_be(:license) { create(:license, starts_at: nil, expires_at: Date.new(2014, 12, 31)) }

      it 'returns correct number of records starting a year ago to license\s expiration date' do
        expect(historical_data_count).to eq(14)
      end
    end

    context 'with a license that has no end date' do
      let_it_be(:license) { create(:license, starts_at: Date.new(2014, 7, 1), expires_at: nil) }

      it 'returns correct number of records from the license\'s start date to today' do
        expect(historical_data_count).to eq(6)
      end
    end
  end

  describe '#historical_max' do
    subject(:historical_max) { license.historical_max }

    let(:license) { create(:license, starts_at: Date.current - 1.month, expires_at: Date.current + 1.month) }

    context 'when using parameters' do
      before do
        (1..12).each do |i|
          create(:historical_data, recorded_at: Date.new(2014, i, 1), active_user_count: i * 100)
        end
      end

      it 'returns max user count for the given time range' do
        from = Date.new(2014, 6, 1)
        to = Date.new(2014, 9, 1)

        expect(license.historical_max(from: from, to: to)).to eq(900)
      end
    end

    context 'with different plans for the license' do
      using RSpec::Parameterized::TableSyntax

      where(:gl_plan, :expected_count) do
        ::License::STARTER_PLAN  | 2
        ::License::PREMIUM_PLAN  | 2
        ::License::ULTIMATE_PLAN | 1
      end

      with_them do
        let(:plan) { gl_plan }
        let(:license) do
          create(:license, plan: plan, starts_at: Date.current - 1.month, expires_at: Date.current + 1.month)
        end

        before do
          license

          create(:group_member, :guest)
          create(:group_member, :reporter)

          HistoricalData.track!
        end

        it 'does not count guest users' do
          expect(historical_max).to eq(expected_count)
        end
      end
    end

    context 'with data inside and outside of the license period' do
      before do
        create(:historical_data, recorded_at: license.starts_at.ago(2.days), active_user_count: 20)
        create(:historical_data, recorded_at: license.starts_at.in(2.days), active_user_count: 10)
        create(:historical_data, recorded_at: license.starts_at.in(5.days), active_user_count: 15)
        create(:historical_data, recorded_at: license.expires_at.in(2.days), active_user_count: 25)
      end

      it 'returns max value for active_user_count for within the license period only' do
        expect(historical_max).to eq(15)
      end
    end

    context 'when license has no start date' do
      let(:license) { create(:license, starts_at: nil, expires_at: Date.current + 1.month) }

      before do
        create(:historical_data, recorded_at: Date.yesterday.ago(1.year), active_user_count: 15)
        create(:historical_data, recorded_at: Date.current.ago(1.year), active_user_count: 12)
        create(:historical_data, recorded_at: license.expires_at.ago(2.days), active_user_count: 10)
      end

      it 'returns max value for active_user_count from up to a year ago' do
        expect(historical_max).to eq(12)
      end
    end

    context 'when license has no expiration date' do
      let(:license) { create(:license, starts_at: Date.current.ago(1.month), expires_at: nil) }

      before do
        create(:historical_data, recorded_at: license.starts_at.in(2.days), active_user_count: 10)
        create(:historical_data, recorded_at: Date.tomorrow, active_user_count: 15)
      end

      it 'returns max value for active_user_count until today' do
        expect(historical_max).to eq(10)
      end
    end
  end

  describe '#maximum_user_count' do
    let(:now) { Date.current }

    it 'returns zero when there is no data' do
      expect(license.maximum_user_count).to eq(0)
    end

    it 'returns historical data' do
      create(:historical_data, active_user_count: 1)

      expect(license.maximum_user_count).to eq(1)
    end

    it 'returns the billable users count' do
      create(:usage_trends_measurement, identifier: :billable_users, count: 2)

      expect(license.maximum_user_count).to eq(2)
    end

    it 'returns the daily billable users count when it is higher than historical data' do
      create(:historical_data, active_user_count: 50)
      create(:usage_trends_measurement, identifier: :billable_users, count: 100)

      expect(license.maximum_user_count).to eq(100)
    end

    it 'returns historical data when it is higher than the billable users count' do
      create(:historical_data, active_user_count: 100)
      create(:usage_trends_measurement, identifier: :billable_users, count: 50)

      expect(license.maximum_user_count).to eq(100)
    end

    it 'returns the correct value when historical data and billable users are equal' do
      create(:historical_data, active_user_count: 100)
      create(:usage_trends_measurement, identifier: :billable_users, count: 100)

      expect(license.maximum_user_count).to eq(100)
    end

    it 'returns the highest value from historical data' do
      create(:historical_data, recorded_at: license.expires_at - 4.months, active_user_count: 130)
      create(:historical_data, recorded_at: license.expires_at - 3.months, active_user_count: 250)
      create(:historical_data, recorded_at: license.expires_at - 1.month, active_user_count: 215)

      expect(license.maximum_user_count).to eq(250)
    end

    it 'uses only the most recent billable users entry' do
      create(:usage_trends_measurement, recorded_at: license.expires_at - 3.months, identifier: :billable_users, count: 150)
      create(:historical_data, recorded_at: license.expires_at - 3.months, active_user_count: 140)
      create(:usage_trends_measurement, recorded_at: license.expires_at - 2.months, identifier: :billable_users, count: 100)

      expect(license.maximum_user_count).to eq(140)
    end

    it 'returns the highest historical data since the license started for a 1 year license' do
      license = build(:license, starts_at: now - 4.months, expires_at: now + 8.months )
      create(:historical_data, recorded_at: license.starts_at - 1.day, active_user_count: 100)
      create(:historical_data, recorded_at: now, active_user_count: 40)

      expect(license.maximum_user_count).to eq(40)
    end

    it 'returns the highest historical data since the license started for a license that lasts 6 months' do
      license = build(:license, starts_at: now - 4.months, expires_at: now + 2.months )
      create(:historical_data, recorded_at: license.starts_at - 1.day, active_user_count: 80)
      create(:historical_data, recorded_at: now, active_user_count: 30)

      expect(license.maximum_user_count).to eq(30)
    end

    it 'returns the highest historical data since the license started for a license that lasts two years' do
      license = build(:license, starts_at: now - 6.months, expires_at: now + 18.months )
      create(:historical_data, recorded_at: license.starts_at - 1.day, active_user_count: 400)
      create(:historical_data, recorded_at: now, active_user_count: 300)

      expect(license.maximum_user_count).to eq(300)
    end

    it 'returns the highest historical data during the license period for an expired license' do
      license = build(:license, starts_at: now - 14.months, expires_at: now - 2.months )
      create(:historical_data, recorded_at: license.expires_at - 1.month, active_user_count: 400)
      create(:historical_data, recorded_at: now, active_user_count: 500)

      expect(license.maximum_user_count).to eq(400)
    end
  end

  describe '#ultimate?' do
    using RSpec::Parameterized::TableSyntax

    let(:license) { build(:license, plan: plan) }

    subject { license.ultimate? }

    where(:plan, :expected) do
      nil | false
      described_class::STARTER_PLAN | false
      described_class::PREMIUM_PLAN | false
      described_class::ULTIMATE_PLAN | true
    end

    with_them do
      it { is_expected.to eq(expected) }
    end
  end

  describe 'Trial Licenses' do
    before do
      ApplicationSetting.create_from_defaults
      stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    end

    describe 'Update trial setting' do
      context 'when the license is not trial' do
        before do
          gl_license.restrictions = { trial: false }
          gl_license.expires_at = Date.tomorrow
        end

        it 'does nothing' do
          license.save

          expect(ApplicationSetting.current.license_trial_ends_on).to be_nil
        end
      end

      context 'when the license is the very first trial' do
        let(:tomorrow) { Date.tomorrow }

        before do
          gl_license.restrictions = { trial: true }
          gl_license.expires_at = tomorrow
        end

        it 'is eligible for trial' do
          expect(described_class.eligible_for_trial?).to be_truthy
        end

        it 'updates the trial setting during create' do
          license.save

          expect(described_class.eligible_for_trial?).to be_falsey
          expect(ApplicationSetting.current.license_trial_ends_on).to eq(tomorrow)
        end
      end

      context 'when the license is a repeated trial' do
        let(:yesterday) { Date.yesterday }

        before do
          gl_license.restrictions = { trial: true }
          gl_license.expires_at = Date.tomorrow
          ApplicationSetting.current.update license_trial_ends_on: yesterday
        end

        it 'does not update existing trial setting' do
          license.save

          expect(ApplicationSetting.current.license_trial_ends_on).to eq(yesterday)
        end

        it 'is not eligible for trial' do
          expect(described_class.eligible_for_trial?).to be_falsey
        end
      end
    end
  end

  describe '.history' do
    before(:all) do
      described_class.delete_all
    end

    it 'does not include the undecryptable license' do
      undecryptable_license = create(:license)
      allow(undecryptable_license).to receive(:license).and_return(nil)

      allow(License).to receive(:all).and_return([undecryptable_license])

      expect(described_class.history.map(&:id)).to be_empty
    end

    it 'returns the licenses sorted by created_at, starts_at and expires_at descending' do
      today = Date.current
      now = Time.current

      past_license = create(:license, created_at: now - 1.month, data: build(:gitlab_license, starts_at: today - 1.month, expires_at: today + 11.months).export)
      expired_license = create(:license, created_at: now, data: build(:gitlab_license, starts_at: today - 1.year, expires_at: today - 1.month).export)
      future_license = create(:license, created_at: now, data: build(:gitlab_license, starts_at: today + 1.month, expires_at: today + 13.months).export)
      another_license = create(:license, created_at: now, data: build(:gitlab_license, starts_at: today - 1.month, expires_at: today + 1.year).export)
      current_license = create(:license, created_at: now, data: build(:gitlab_license, starts_at: today - 15.days, expires_at: today + 11.months).export)

      expect(described_class.history.map(&:id)).to eq(
        [
          future_license.id,
          current_license.id,
          another_license.id,
          past_license.id,
          expired_license.id
        ]
      )
    end
  end

  describe '#edition' do
    let(:ultimate) { build(:license, plan: 'ultimate') }
    let(:premium) { build(:license, plan: 'premium') }
    let(:starter) { build(:license, plan: 'starter') }
    let(:old) { build(:license, plan: 'other') }

    it 'have expected values' do
      expect(ultimate.edition).to eq('EEU')
      expect(premium.edition).to eq('EEP')
      expect(starter.edition).to eq('EES')
      expect(old.edition).to eq('EE')
    end
  end

  def set_restrictions(opts)
    date = described_class.current.starts_at

    gl_license.restrictions = {
      active_user_count: opts[:restricted_user_count],
      previous_user_count: opts[:previous_user_count],
      trueup_quantity: opts[:trueup_quantity],
      trueup_from: (date - 1.year).to_s,
      trueup_to: date.to_s,
      reconciliation_completed: opts[:reconciliation_completed]
    }.compact
  end

  describe '#paid?' do
    where(:plan, :paid_result) do
      License::STARTER_PLAN  | true
      License::PREMIUM_PLAN  | true
      License::ULTIMATE_PLAN | true
      nil                    | true
    end

    with_them do
      let(:license) { build(:license, plan: plan) }

      subject { license.paid? }

      it do
        is_expected.to eq(paid_result)
      end
    end
  end

  describe '#started?' do
    where(:starts_at, :result) do
      Date.current - 1.month | true
      Date.current           | true
      Date.current + 1.month | false
    end

    with_them do
      let(:gl_license) { build(:gitlab_license, starts_at: starts_at) }

      subject { license.started? }

      it do
        is_expected.to eq(result)
      end
    end
  end

  describe '#future_dated?' do
    where(:starts_at, :result) do
      Date.current - 1.month | false
      Date.current           | false
      Date.current + 1.month | true
    end

    with_them do
      let(:gl_license) { build(:gitlab_license, starts_at: starts_at) }

      subject { license.future_dated? }

      it do
        is_expected.to eq(result)
      end
    end
  end

  describe '#cloud_license?' do
    subject { license.cloud_license? }

    context 'when no license provided' do
      before do
        license.data = nil
      end

      it { is_expected.to be false }
    end

    context 'when the license has cloud licensing disabled' do
      let(:gl_license) { build(:gitlab_license, cloud_licensing_enabled: false) }

      it { is_expected.to be false }
    end

    context 'when the license has cloud licensing enabled' do
      let(:gl_license) { build(:gitlab_license, cloud_licensing_enabled: true) }

      it { is_expected.to be true }
    end
  end

  describe '#customer_service_enabled?' do
    subject { license.customer_service_enabled? }

    context 'when no license provided' do
      before do
        license.data = nil
      end

      it { is_expected.to be false }
    end

    context 'when the license has usage ping required metrics disabled' do
      let(:gl_license) { build(:gitlab_license, operational_metrics_enabled: false) }

      it { is_expected.to be false }
    end

    context 'when the license has usage ping required metrics enabled' do
      let(:gl_license) { build(:gitlab_license, operational_metrics_enabled: true) }

      it { is_expected.to be true }
    end
  end

  describe '#license_type' do
    subject { license.license_type }

    context 'when the license is not a cloud license' do
      it { is_expected.to eq(described_class::LICENSE_FILE_TYPE) }
    end

    context 'when the license is a cloud license' do
      let(:gl_license) { build(:gitlab_license, cloud_licensing_enabled: true) }

      it { is_expected.to eq(described_class::CLOUD_LICENSE_TYPE) }
    end
  end

  describe '#auto_renew' do
    it 'is false' do
      expect(license.auto_renew).to be false
    end
  end

  describe '#active_user_count_threshold' do
    subject { license.active_user_count_threshold }

    it 'returns nil for license with unlimited user count' do
      allow(license).to receive(:restricted_user_count).and_return(nil)

      expect(subject).to be_nil
    end

    context 'for license with users' do
      where(:restricted_user_count, :active_user_count, :percentage, :threshold_value) do
        3    | 2    | false | 1
        20   | 18   | false | 2
        90   | 80   | true  | 10
        300  | 275  | true  | 8
        1200 | 1100 | true  | 5
      end

      with_them do
        before do
          allow(license).to receive(:restricted_user_count).and_return(restricted_user_count)
          allow(license).to receive(:daily_billable_users_count).and_return(active_user_count)
        end

        it { is_expected.not_to be_nil }
        it { is_expected.to include(value: threshold_value, percentage: percentage) }
      end
    end
  end

  describe '#active_user_count_threshold_reached?' do
    subject { license.active_user_count_threshold_reached? }

    where(:restricted_user_count, :daily_billable_users_count, :result) do
      10   | 9   | true
      nil  | 9   | false
      10   | 15  | false
      100  | 95  | true
    end

    with_them do
      before do
        allow(license).to receive(:daily_billable_users_count).and_return(daily_billable_users_count)
        allow(license).to receive(:restricted_user_count).and_return(restricted_user_count)
      end

      it { is_expected.to eq(result) }
    end
  end

  describe '#restricted_user_count?' do
    subject { license.restricted_user_count? }

    where(:restricted_user_count, :result) do
      nil | false
      0   | false
      1   | true
      10  | true
    end

    with_them do
      before do
        allow(license).to receive(:restricted_user_count).and_return(restricted_user_count)
      end

      it { is_expected.to eq(result) }
    end
  end

  describe '#licensee_name' do
    subject { license.licensee_name }

    let(:gl_license) { build(:gitlab_license, licensee: { 'Name' => 'User Example' }) }

    it { is_expected.to eq('User Example') }
  end

  describe '#licensee_email' do
    subject { license.licensee_email }

    let(:gl_license) { build(:gitlab_license, licensee: { 'Email' => 'user@example.com' }) }

    it { is_expected.to eq('user@example.com') }
  end

  describe '#licensee_company' do
    subject { license.licensee_company }

    let(:gl_license) { build(:gitlab_license, licensee: { 'Company' => 'Example Inc.' }) }

    it { is_expected.to eq('Example Inc.') }
  end

  describe '#activated_at' do
    subject { license.activated_at }

    let(:license) do
      gl_license = build(:gitlab_license, activated_at: activated_at)
      build(:license, data: gl_license.export, created_at: 5.days.ago)
    end

    context 'when activated_at is set within the license data' do
      let(:activated_at) { Date.yesterday.to_datetime }

      it { is_expected.to eq(activated_at) }
    end

    context 'when activated_at is not set within the license data' do
      let(:activated_at) { nil }

      it { is_expected.to eq(license.created_at) }
    end
  end
end
