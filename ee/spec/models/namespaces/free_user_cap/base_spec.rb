# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::FreeUserCap::Base, :saas do
  let_it_be(:namespace) { create(:group_with_plan, :private, plan: :free_plan) }

  describe '#enforce_cap?' do
    before do
      stub_ee_application_setting(dashboard_limit_enabled: true)
    end

    it 'raises an error for feature enabled definition' do
      expect { described_class.new(namespace).enforce_cap? }.to raise_error(NotImplementedError)
    end
  end

  describe '#over_limit?' do
    it 'raises an error for limit definition' do
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:enforce_cap?).and_return(true)
      end

      expect { described_class.new(namespace).over_limit? }.to raise_error(NotImplementedError)
    end
  end
end
