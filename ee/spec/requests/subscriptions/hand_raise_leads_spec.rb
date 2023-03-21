# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Hand Raise Leads', feature_category: :purchase do
  describe '#create' do
    it 'directs to new controller', type: :routing do
      expect(post('/-/trials/create_hand_raise_lead')).to route_to('subscriptions/hand_raise_leads#create')
    end
  end
end
