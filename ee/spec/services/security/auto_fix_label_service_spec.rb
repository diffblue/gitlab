# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::AutoFixLabelService, feature_category: :vulnerability_management do
  describe '#execute' do
    subject(:execute) { described_class.new(container: project, current_user: bot).execute }

    let_it_be(:project) { create(:project) }
    let_it_be(:bot) { create(:user, :security_bot) }

    let(:label_attributes) { described_class::LABEL_PROPERTIES }
    let(:title) { label_attributes[:title] }
    let(:color) { label_attributes[:color] }
    let(:description) { label_attributes[:description] }

    context 'when label exists' do
      let!(:label) { create(:label, project: project, title: title) }

      it 'finds existing label' do
        result = execute

        expect(result).to be_success
        expect(execute.payload).to eq(label: label)
      end
    end

    context 'when label does not exists' do
      it 'creates a new label' do
        result = execute
        label = result.payload[:label]

        expect(result).to be_success
        expect(label.title).to eq(title)
        expect(label.color).to be_color(color)
        expect(label.description).to eq(description)
      end
    end
  end
end
