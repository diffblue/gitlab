# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Audit::UserSettingChangesAuditor, feature_category: :user_profile do
  using RSpec::Parameterized::TableSyntax
  describe '#execute' do
    let_it_be(:user) { create(:user) }

    subject(:user_setting_changes_auditor) { described_class.new(user) }

    before do
      stub_licensed_features(extended_audit_events: true, external_audit_events: true)
    end

    context 'when user setting is updated' do
      where(:column, :change, :event, :change_from, :change_to) do
        'private_profile' | 'user_profile_visiblity' | 'user_profile_visiblity_updated' | true  | false
        'private_profile' | 'user_profile_visiblity' | 'user_profile_visiblity_updated' | false | true
      end

      with_them do
        before do
          user.update!(column.to_sym => change_from)
        end

        it 'calls auditor' do
          user.update!(column.to_sym => change_to)

          expect(Gitlab::Audit::Auditor).to receive(:audit).with(
            {
              name: event,
              author: user,
              scope: user,
              target: user,
              message: "Changed #{change} from #{change_from} to #{change_to}",
              additional_details: {
                change: change.to_s,
                from: change_from,
                to: change_to
              },
              target_details: nil
            }
          ).and_call_original

          user_setting_changes_auditor.execute
        end
      end
    end
  end
end
