# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::UserNamespace, type: :model, feature_category: :shared do
  describe '.namespace_settings' do
    let(:user) { create(:user) }

    it 'returns new instance of namespace settings when user does not have one created' do
      user.namespace.namespace_settings.destroy!

      expect(user.namespace.namespace_settings).not_to be_persisted
    end

    it 'returns saved namespace settings when user has one' do
      expect(user.namespace.namespace_settings).to be_persisted
    end
  end
end
