# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptionHistory do
  describe '.create_from_change' do
    context 'when supplied an invalid change type' do
      it 'raises an error' do
        expect do
          described_class.create_from_change(
            :invalid_change_type,
            { 'id' => 1 }
          )
        end.to raise_error(ArgumentError, "'invalid_change_type' is not a valid change_type")
      end
    end

    context 'when the required attributes are not present' do
      it 'returns an error' do
        record = described_class.create_from_change(
          :gitlab_subscription_updated,
          { 'id' => nil }
        )

        expect(record.errors.attribute_names).to include(:gitlab_subscription_id)
      end
    end

    context 'when supplied extra attributes than exist on the history table' do
      it 'saves the tracked attributes without error' do
        current_time = Time.current

        record = described_class.create_from_change(
          :gitlab_subscription_updated,
          {
            'id' => 1,
            'created_at' => current_time,
            'updated_at' => current_time,
            'non_existent_attribute' => true,
            'seats_in_use' => 10,
            'trial' => true,
            'seats' => 15
          }
        )

        expect(record).to be_valid
        expect(record).to be_persisted

        expect(record).to have_attributes(
          'gitlab_subscription_id' => 1,
          'gitlab_subscription_created_at' => current_time,
          'gitlab_subscription_updated_at' => current_time,
          'trial' => true,
          'seats' => 15
        )

        expect(record.attributes.keys).not_to include('non_existent_attribute', 'seats_in_use')
      end
    end
  end
end
