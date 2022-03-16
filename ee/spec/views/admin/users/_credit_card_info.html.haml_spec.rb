# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/users/_credit_card_info.html.haml', :saas do
  include ApplicationHelper

  let_it_be(:user, reload: true) { create(:user) }

  def render
    super(
      partial: 'admin/users/credit_card_info',
      formats: :html,
      locals: { user: user }
    )
  end

  it 'shows not validated' do
    render

    expect(rendered).to match /\bNo\b/
    expect(rendered.scan(/<li\b/m).size).to eq(1)
  end

  context 'when user is validated' do
    let!(:credit_card_validation) do
      create(
        :credit_card_validation,
        user: user,
        network: 'AmericanExpress',
        last_digits: 2
      )
    end

    it 'shows card data' do
      render

      expect(rendered.scan(/<li\b/m).size).to eq(5)
      expect(rendered).to match /\b0002\b/
      expect(rendered).to match /\bAmericanExpress\b/
      expect(rendered).to include(credit_card_validation.holder_name)
      expect(rendered).not_to match /\bNo\b/
    end

    context 'when network is missing' do
      let!(:credit_card_validation) do
        create(:credit_card_validation, user: user, network: nil)
      end

      it 'does not show network' do
        render

        expect(rendered).not_to match /\bAmericanExpress\b/
        expect(rendered.scan(/<li\b/m).size).to eq(4)
      end
    end
  end
end
