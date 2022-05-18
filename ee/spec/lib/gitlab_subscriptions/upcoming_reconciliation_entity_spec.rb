# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::UpcomingReconciliationEntity do
  subject { described_class.new(current_user: user, namespace: namespace) }

  let(:upcoming_reconciliation) { build(:upcoming_reconciliation, :self_managed) }
  let(:user) { build(:user) }
  let(:namespace) { nil }

  before do
    allow(GitlabSubscriptions::UpcomingReconciliation).to receive(:next).with(nil).and_return(upcoming_reconciliation)
  end

  it { is_expected.to delegate_method(:next_reconciliation_date).to(:upcoming_reconciliation) }
  it { is_expected.to delegate_method(:display_alert?).to(:upcoming_reconciliation) }

  describe '#has_permissions?' do
    context 'with namespace' do
      let(:namespace) { build(:namespace, owner: user) }

      it 'checks if user can admin_namespace' do
        expect(Ability).to receive(:allowed?).with(user, :admin_namespace, namespace).and_return(true)

        expect(subject.has_permissions?).to eq(true)
      end
    end

    context 'without namespace' do
      it 'checks if user is admin' do
        expect(user).to receive(:can_admin_all_resources?).and_return(true)

        expect(subject.has_permissions?).to eq(true)
      end

      context 'when current_user is nil' do
        let(:current_user) { nil }

        it 'returns false' do
          expect(subject.has_permissions?).to eq(false)
        end
      end
    end
  end

  describe '#cookie_key' do
    let(:upcoming_reconciliation) { build(:upcoming_reconciliation, :saas, namespace: namespace) }

    before do
      allow(user).to receive(:id).and_return(1)
    end

    context 'with namespace' do
      let(:namespace) { build(:namespace, owner: user) }

      before do
        stub_ee_application_setting(should_check_namespace_plan: true)

        allow(namespace).to receive(:id).and_return(2)
        allow(GitlabSubscriptions::UpcomingReconciliation).to receive(:next).with(namespace.id).and_return(upcoming_reconciliation)
      end

      it 'includes namespace id in key' do
        expected_key = "#{described_class::COOKIE_KEY_PREFIX}_#{user.id}_#{namespace.id}_#{upcoming_reconciliation.next_reconciliation_date}"
        expect(subject.cookie_key).to eq(expected_key)
      end
    end

    context 'without namespace' do
      it 'does not include namespace id in cookie key' do
        expected_key = "#{described_class::COOKIE_KEY_PREFIX}_#{user.id}_#{upcoming_reconciliation.next_reconciliation_date}"
        expect(subject.cookie_key).to eq(expected_key)
      end
    end
  end

  describe '#display_alert?' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:license) { create(:license) }

    subject(:entity) do
      described_class.new(
        current_user: user,
        namespace: with_namespace ? namespace : nil
      )
    end

    before do
      allow(License).to receive(:current).and_return(license)

      if with_namespace
        allow(GitlabSubscriptions::UpcomingReconciliation).to receive(:next)
          .with(namespace.id).and_return(upcoming_reconciliation)
      end
    end

    where(:upcoming_reconciliation_display_alert, :with_namespace, :offline_cloud_license, :expected) do
      false | true | true | false
      false | true | false | false
      true | true | true | true
      true | true | false | true
      true | false | false | true
      true | false | true | false
    end

    with_them do
      it "returns result" do
        allow(upcoming_reconciliation).to receive(:display_alert?)
          .and_return(upcoming_reconciliation_display_alert)
        allow(::License.current).to receive(:offline_cloud_license?)
          .and_return(offline_cloud_license)

        expect(entity.display_alert?).to eq(expected)
      end
    end

    context 'without upcoming_reconciliation' do
      let(:upcoming_reconciliation) { nil }
      let(:with_namespace) { true }

      it 'returns false' do
        expect(entity.display_alert?).to eq(false)
      end

      context 'without namespace' do
        let(:with_namespace) { false }

        it 'returns false' do
          expect(entity.display_alert?).to eq(false)
        end
      end
    end
  end
end
