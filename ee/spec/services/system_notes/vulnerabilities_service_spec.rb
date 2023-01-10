# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemNotes::VulnerabilitiesService do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:author) { create(:user) }

  let(:service) { described_class.new(noteable: noteable, project: project, author: author) }

  describe '#change_vulnerability_state' do
    subject { service.change_vulnerability_state }

    %w(dismissed resolved confirmed).each do |state|
      context "state changed to #{state}" do
        let(:noteable) { create(:vulnerability, project: project, state: state) }

        it_behaves_like 'a system note', exclude_project: true do
          let(:action) { "vulnerability_#{state}" }
        end

        it 'creates the note text correctly' do
          expect(subject.note).to eq("changed vulnerability status to #{state}")
        end
      end
    end

    context 'when body provided' do
      subject { service.change_vulnerability_state(comment) }

      let(:noteable) { create(:vulnerability, project: project, state: 'detected') }
      let(:comment) { 'This vulnerability type has been deprecated' }

      it_behaves_like 'a system note', exclude_project: true do
        let(:action) { "vulnerability_detected" }
      end

      it 'creates the note text correctly' do
        expect(subject.note).to eq(comment)
      end
    end
  end
end
