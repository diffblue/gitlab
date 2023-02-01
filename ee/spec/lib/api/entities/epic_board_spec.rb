# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::EpicBoard, feature_category: :portfolio_management do
  subject { described_class.new(epic_board).as_json }

  let(:epic_board) { build(:epic_board) }

  it 'exposes correct attributes' do
    expect(subject.keys)
      .to contain_exactly(:id, :name, :hide_backlog_list, :hide_closed_list, :group, :labels, :lists)
  end
end
