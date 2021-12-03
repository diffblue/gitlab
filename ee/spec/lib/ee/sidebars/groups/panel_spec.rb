# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Panel do
  let(:group) { build(:group, id: non_existing_record_id) }
  let(:context) { Sidebars::Groups::Context.new(current_user: nil, container: group) }

  subject(:panel) { described_class.new(context) }

  describe 'BillingMenu' do
    context 'with candidate experience' do
      before do
        stub_experiments(billing_in_side_nav: :candidate)
      end

      it 'contains the billing menu' do
        expect(contains_billing_menu?).to be(true)
      end
    end

    context 'with control experience' do
      before do
        stub_experiments(billing_in_side_nav: :control)
      end

      it 'does not contain the billing menu' do
        expect(contains_billing_menu?).to be(false)
      end
    end

    def contains_billing_menu?
      contains_menu?(Sidebars::Groups::Menus::BillingMenu)
    end
  end

  def contains_menu?(menu)
    panel.instance_variable_get(:@menus).any? { |i| i.is_a?(menu) }
  end
end
