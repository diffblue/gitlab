# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItem do
  describe '#widgets' do
    subject { build(:work_item).widgets }

    context 'for weight widget' do
      context 'when issuable weights is licensed' do
        before do
          stub_licensed_features(issue_weights: true)
        end

        it 'returns an instance of the weight widget' do
          is_expected.to include(instance_of(WorkItems::Widgets::Weight))
        end
      end

      context 'when issuable weights is unlicensed' do
        before do
          stub_licensed_features(issue_weights: false)
        end

        it 'omits an instance of the weight widget' do
          is_expected.not_to include(instance_of(WorkItems::Widgets::Weight))
        end
      end
    end

    context 'for verification status widget' do
      subject { build(:work_item, :requirement).widgets }

      context 'when requirements is licensed' do
        before do
          stub_licensed_features(requirements: true)
        end

        it 'returns an instance of the verification status widget' do
          is_expected.to include(instance_of(WorkItems::Widgets::VerificationStatus))
        end
      end

      context 'when verification status is unlicensed' do
        before do
          stub_licensed_features(requirements: false)
        end

        it 'omits an instance of the verification status widget' do
          is_expected.not_to include(instance_of(WorkItems::Widgets::VerificationStatus))
        end
      end
    end
  end
end
