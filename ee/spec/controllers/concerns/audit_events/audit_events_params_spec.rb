# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::AuditEventsParams, feature_category: :audit_events do
  let_it_be(:current_user) { build(:user) }

  concern = described_class

  controller(ActionController::Base) do
    # `described_class` is not available in this context
    include concern
  end

  describe '#filter_by_author' do
    let(:params) do
      {
        created_before: '2022-09-27',
        created_after: '2022-09-14',
        sort: 'created_asc',
        author_username: 'admin',
        author_id: '123',
        foo: 'bar'
      }
    end

    it 'returns params when the user has permission to view all events' do
      allow(controller).to receive(:current_user).and_return(current_user)
      allow(controller).to receive(:can_view_events_from_all_members?).and_return(true)

      expect(controller.filter_by_author(params)).to eq(params)
    end

    it 'returns safe params with the current user id when the user lacks permission to view all events' do
      allow(controller).to receive(:current_user).and_return(current_user)
      allow(controller).to receive(:can_view_events_from_all_members?).and_return(false)

      expect(controller.filter_by_author(params)).to eq(
        {
          created_before: '2022-09-27',
          created_after: '2022-09-14',
          sort: 'created_asc',
          author_id: current_user.id
        }
      )
    end
  end
end
