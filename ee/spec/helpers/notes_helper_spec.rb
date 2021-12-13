# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NotesHelper do
  let_it_be(:vulnerability) { create(:vulnerability) }

  describe '#notes_url' do
    context 'for vulnerability' do
      it 'return vulnerability notes path for vulnerability' do
        @vulnerability = vulnerability

        expect(notes_url).to eq("/#{@vulnerability.project.full_path}/-/security/vulnerabilities/#{@vulnerability.id}/notes")
      end
    end
  end

  describe '#discussions_path' do
    subject { discussions_path(issuable) }

    context 'for vulnerability' do
      let(:issuable) { vulnerability }

      it { is_expected.to eq("/#{vulnerability.project.full_path}/-/security/vulnerabilities/#{vulnerability.id}/discussions.json") }
    end
  end
end
