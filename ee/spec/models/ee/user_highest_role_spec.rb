# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserHighestRole do
  describe 'validations' do
    it do
      is_expected.to validate_inclusion_of(:highest_access_level)
                       .in_array(Gitlab::Access.values_with_minimal_access).allow_nil
    end
  end
end
