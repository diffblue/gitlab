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

  describe '#notes_data' do
    let_it_be(:epic) { create(:epic) }

    let(:notes_data) { helper.notes_data(epic) }

    before do
      @group = epic.group
      @noteable = @epic = epic

      allow(helper).to receive(:current_user).and_return(epic.author)
    end

    it 'includes info about the noteable', :aggregate_failures do
      expect(notes_data[:noteableType]).to eq('epic')
      expect(notes_data[:noteableId]).to eq(epic.id)
      expect(notes_data[:projectId]).to be_nil
      expect(notes_data[:groupId]).to eq(epic.group_id)
    end
  end
end
