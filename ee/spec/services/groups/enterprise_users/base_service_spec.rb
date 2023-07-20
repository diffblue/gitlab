# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::EnterpriseUsers::BaseService, :saas, feature_category: :user_management do
  subject(:service) { described_class.new }

  describe '#execute' do
    it 'raises NotImplementedError' do
      expect { service.execute }.to raise_error(NotImplementedError)
    end
  end
end
