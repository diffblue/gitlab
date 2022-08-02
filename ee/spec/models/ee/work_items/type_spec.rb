# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Type do
  describe '.available_widgets' do
    subject { described_class.available_widgets }

    it 'returns list of all possible widgets' do
      is_expected.to contain_exactly(
        ::WorkItems::Widgets::Description,
        ::WorkItems::Widgets::Hierarchy,
        ::WorkItems::Widgets::Assignees,
        ::WorkItems::Widgets::Weight,
        ::WorkItems::Widgets::StartAndDueDate,
        ::WorkItems::Widgets::VerificationStatus
      )
    end
  end
end
