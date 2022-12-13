# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe FixStateColumnInFileRegistry, :geo, feature_category: :geo_replication do
  let(:registry) { table(:file_registry) }

  it 'correctly sets registry state value' do
    reg0 = registry.create!(file_id: 1, state: 0, success: false, file_type: 'placeholder')
    reg1 = registry.create!(file_id: 2, state: 0, success: true, file_type: 'placeholder')
    reg2 = registry.create!(file_id: 3, state: 1, success: false, file_type: 'placeholder')
    reg3 = registry.create!(file_id: 4, state: 2, success: true, file_type: 'placeholder')
    reg4 = registry.create!(file_id: 5, state: 3, success: false, file_type: 'placeholder')

    migrate!

    expect(registry.where(state: 0)).to contain_exactly(reg0)
    expect(registry.where(state: 2)).to contain_exactly(reg1, reg3)
    expect(registry.where(state: 1)).to contain_exactly(reg2)
    expect(registry.where(state: 3)).to contain_exactly(reg4)
  end
end
