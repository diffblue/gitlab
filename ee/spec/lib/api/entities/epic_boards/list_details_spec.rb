# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::EpicBoards::ListDetails, feature_category: :portfolio_management do
  subject { described_class.new(epic_list).as_json }

  let(:epic_list) { build(:epic_list) }

  it 'exposes correct attributes' do
    expect(subject.keys).to contain_exactly(:id, :label, :position, :list_type, :collapsed)
  end
end
