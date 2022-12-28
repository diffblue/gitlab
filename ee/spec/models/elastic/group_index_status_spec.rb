# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::GroupIndexStatus, feature_category: :global_search do
  subject(:index_status) { described_class.new }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:namespace_id) }
    it { is_expected.not_to allow_value(nil).for(:namespace_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:group).with_foreign_key('namespace_id') }
  end
end
