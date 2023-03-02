# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Epics::RelatedEpicLinks::UsageDataHelper, feature_category: :portfolio_management do
  using RSpec::Parameterized::TableSyntax

  describe '#track_related_epics_event_for' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }

    subject(:related_epic_link_service) do
      Class.new do
        attr_accessor :current_user

        include Epics::RelatedEpicLinks::UsageDataHelper

        def initialize(user)
          @current_user = user
        end
      end
    end

    let(:service) { related_epic_link_service.new(user) }

    where(:link_type, :event_type, :tracking_method) do
      IssuableLink::TYPE_RELATES_TO    | :added   | :track_linked_epic_with_type_relates_to_added
      IssuableLink::TYPE_RELATES_TO    | :removed | :track_linked_epic_with_type_relates_to_removed
      IssuableLink::TYPE_BLOCKS        | :added   | :track_linked_epic_with_type_blocks_added
      IssuableLink::TYPE_BLOCKS        | :removed | :track_linked_epic_with_type_blocks_removed
      IssuableLink::TYPE_IS_BLOCKED_BY | :added   | :track_linked_epic_with_type_is_blocked_by_added
      IssuableLink::TYPE_IS_BLOCKED_BY | :removed | :track_linked_epic_with_type_is_blocked_by_removed
    end

    with_them do
      it 'calls correct tracking method on EpicActivityUniqueCounter' do
        expect(Gitlab::UsageDataCounters::EpicActivityUniqueCounter).to receive(tracking_method)
          .with(author: user, namespace: group)

        service.send(:track_related_epics_event_for, link_type: link_type, event_type: event_type, namespace: group)
      end
    end
  end
end
