# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LabelPresenter, feature_category: :team_planning do
  let(:project) { build_stubbed(:project) }

  describe '#scoped_label?' do
    subject { label.scoped_label? }

    context 'with scoped_labels enabled' do
      before do
        stub_licensed_features(scoped_labels: true)
      end

      context 'with project label with context subject set' do
        let(:label) { build_stubbed(:label, title: 'key::val', project: project).present(issuable_subject: project) }

        it { is_expected.to be_truthy }
      end

      context 'with project label without context subject' do
        let(:label) { build_stubbed(:label, title: 'key::val', project: project).present(issuable_subject: nil) }

        it { is_expected.to be_truthy }
      end
    end

    context 'with scoped_labels disabled' do
      before do
        stub_licensed_features(scoped_labels: false)
      end

      context 'with project label with context subject set' do
        let(:label) { build(:label, title: 'key::val', project: project).present(issuable_subject: project) }

        it { is_expected.to be_falsey }
      end
    end
  end
end
