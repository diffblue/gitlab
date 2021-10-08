# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/users/show.html.haml' do
  let_it_be(:user) { create(:user) }

  let(:page) { Nokogiri::HTML.parse(rendered) }
  let(:status) { page.at('#credit-card-status')&.text }

  before do
    assign(:user, user)
  end

  it 'does not include credit card validation status' do
    render

    expect(rendered).not_to include('Credit card validated')
    expect(status).to be_nil
  end

  context 'Gitlab.com' do
    before do
      allow(::Gitlab).to receive(:com?).and_return(true)
    end

    it 'includes credit card validation status' do
      render

      expect(status).to match /Validated:\s+No/
    end

    context 'when user is validated' do
      let!(:validation) { create(:credit_card_validation, user: user) }

      it 'includes credit card validation status' do
        render

        expect(status).to include 'Validated at:'
      end
    end
  end
end
