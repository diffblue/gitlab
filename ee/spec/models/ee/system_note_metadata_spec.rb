# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::SystemNoteMetadata do
  %i[
    vulnerability_confirmed vulnerability_dismissed vulnerability_resolved vulnerability_detected
  ].each do |action|
    context 'when action type is valid' do
      subject do
        build(:system_note_metadata, note: build(:note), action: action )
      end

      it { is_expected.to be_valid }
    end
  end
end
