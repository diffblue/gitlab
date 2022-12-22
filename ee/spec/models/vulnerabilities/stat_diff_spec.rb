# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::StatDiff, feature_category: :vulnerability_management do
  using RSpec::Parameterized::TableSyntax

  let!(:vulnerability) { create(:vulnerability, :detected, severity: :high, title: 'Title') }
  let(:stat_diff) { described_class.new(vulnerability) }
  let(:update_vulnerability) {}

  describe '#update_required?' do
    subject(:update_required?) { update_vulnerability.then { stat_diff.update_required? } }

    context 'when the vulnerability is destroyed' do
      let(:update_vulnerability) { vulnerability.destroy! }

      it { is_expected.to be_truthy }
    end

    context 'when the vulnerability is not destroyed' do
      context 'when the severity is changed' do
        let(:update_vulnerability) { vulnerability.update_attribute(:severity, :critical) }

        it { is_expected.to be_truthy }
      end

      context 'when the severity is not changed' do
        context 'when the state is changed' do
          where(:from, :to, :is_update_required) do
            'confirmed' | 'detected'  | false
            'confirmed' | 'resolved'  | true
            'confirmed' | 'dismissed' | true

            'detected'  | 'confirmed' | false
            'detected'  | 'resolved'  | true
            'detected'  | 'dismissed' | true

            'resolved'  | 'dismissed' | false
            'resolved'  | 'confirmed' | true
            'resolved'  | 'detected'  | true

            'dismissed' | 'resolved'  | false
            'dismissed' | 'confirmed' | true
            'dismissed' | 'detected'  | true
          end

          with_them do
            let(:update_vulnerability) { vulnerability.update_attribute(:state, to) }

            before do
              vulnerability.update_attribute(:state, from)
            end

            it { is_expected.to eq(is_update_required) }
          end
        end

        context 'when the state is not changed' do
          let(:update_vulnerability) { vulnerability.update_attribute(:title, 'New Title') }

          it { is_expected.to be_falsey }
        end
      end
    end
  end

  describe '#changes' do
    subject(:changes) { update_vulnerability.then { stat_diff.changes } }

    context 'when the vulnerability is destroyed' do
      let(:update_vulnerability) { vulnerability.destroy! }
      let(:expected_changes) { { 'total' => -1, 'high' => -1 } }

      it { is_expected.to eq(expected_changes) }
    end

    context 'when the vulnerability is not destroyed' do
      context 'when the severity is changed' do
        context 'when the state is not changed' do
          let(:update_vulnerability) { vulnerability.update_attribute(:severity, :critical) }
          let(:expected_changes) { { 'total' => 0, 'high' => -1, 'critical' => 1 } }

          it { is_expected.to eq(expected_changes) }
        end

        context 'when the state is changed' do
          where(:from, :to, :expected_changes) do
            'confirmed' | 'detected'  | { 'total' => 0, 'high' => -1, 'critical' => 1 }
            'confirmed' | 'resolved'  | { 'total' => -1, 'high' => -1 }
            'confirmed' | 'dismissed' | { 'total' => -1, 'high' => -1 }

            'detected'  | 'confirmed' | { 'total' => 0, 'high' => -1, 'critical' => 1 }
            'detected'  | 'resolved'  | { 'total' => -1, 'high' => -1 }
            'detected'  | 'dismissed' | { 'total' => -1, 'high' => -1 }

            'resolved'  | 'dismissed' | { 'total' => 0 }
            'resolved'  | 'confirmed' | { 'total' => 1, 'critical' => 1 }
            'resolved'  | 'detected'  | { 'total' => 1, 'critical' => 1 }

            'dismissed' | 'resolved'  | { 'total' => 0 }
            'dismissed' | 'confirmed' | { 'total' => 1, 'critical' => 1 }
            'dismissed' | 'detected'  | { 'total' => 1, 'critical' => 1 }
          end

          with_them do
            let(:update_vulnerability) { vulnerability.update!(state: to, severity: :critical) }

            before do
              vulnerability.update_attribute(:state, from)
            end

            it { is_expected.to eq(expected_changes) }
          end
        end
      end

      context 'when the severity is not changed' do
        context 'when the state is changed' do
          where(:from, :to, :expected_changes) do
            'confirmed' | 'detected'  | { 'total' => 0 }
            'confirmed' | 'resolved'  | { 'total' => -1, 'high' => -1 }
            'confirmed' | 'dismissed' | { 'total' => -1, 'high' => -1 }

            'detected'  | 'confirmed' | { 'total' => 0 }
            'detected'  | 'resolved'  | { 'total' => -1, 'high' => -1 }
            'detected'  | 'dismissed' | { 'total' => -1, 'high' => -1 }

            'resolved'  | 'dismissed' | { 'total' => 0 }
            'resolved'  | 'confirmed' | { 'total' => 1, 'high' => 1 }
            'resolved'  | 'detected'  | { 'total' => 1, 'high' => 1 }

            'dismissed' | 'resolved'  | { 'total' => 0 }
            'dismissed' | 'confirmed' | { 'total' => 1, 'high' => 1 }
            'dismissed' | 'detected'  | { 'total' => 1, 'high' => 1 }
          end

          with_them do
            let(:update_vulnerability) { vulnerability.update_attribute(:state, to) }

            before do
              vulnerability.update_attribute(:state, from)
            end

            it { is_expected.to eq(expected_changes) }
          end
        end

        context 'when the state is not changed' do
          let(:update_vulnerability) { vulnerability.update_attribute(:title, 'New Title') }
          let(:expected_changes) { { 'total' => 0 } }

          it { is_expected.to eq(expected_changes) }
        end
      end
    end
  end

  describe '#changed_attributes' do
    subject { stat_diff.changed_attributes }

    context 'when there are changes' do
      let(:expected_attribute_names) { %w(total high) }

      before do
        vulnerability.destroy!
      end

      it { is_expected.to eq(expected_attribute_names) }
    end

    context 'when there is no change' do
      let(:expected_attribute_names) { [] }

      before do
        vulnerability.reload
      end

      it { is_expected.to eq(expected_attribute_names) }
    end
  end

  describe '#changed_values' do
    subject { stat_diff.changed_values }

    context 'when there are changes' do
      let(:expected_values) { [-1, -1] }

      before do
        vulnerability.destroy!
      end

      it { is_expected.to eq(expected_values) }
    end

    context 'when there is no change' do
      let(:expected_values) { [] }

      before do
        vulnerability.reload
      end

      it { is_expected.to eq(expected_values) }
    end
  end
end
