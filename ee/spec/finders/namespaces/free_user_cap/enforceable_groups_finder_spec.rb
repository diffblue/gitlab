# frozen_string_literal: true

require 'spec_helper'

# Interim feature category experimentation_conversion used here while waiting for
# https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/113300 to merge
RSpec.describe Namespaces::FreeUserCap::EnforceableGroupsFinder, feature_category: :experimentation_activation do
  subject(:finder) { described_class.new.execute }

  before do
    stub_ee_application_setting should_check_namespace_plan: true
  end

  describe '#execute', :saas do
    let_it_be(:private_free) { create :group_with_plan, :private, plan: :free_plan }
    let_it_be(:public_free) { create :group_with_plan, :public, plan: :free_plan }
    let_it_be(:private_premium) { create :group_with_plan, :private, plan: :premium_plan }
    let_it_be(:private_premium_trial) do
      create :group_with_plan, :private, plan: :premium_plan, trial_ends_on: Date.current.advance(months: 1)
    end

    context 'with out being previously notified' do
      it 'finds private free groups' do
        expect(finder.count).to eq(1)
        expect(finder.all).to match_array([private_free])
      end
    end

    context 'when applicable namespace is not a root namespace' do
      let_it_be(:parent) { create :group }

      before do
        private_free.update! parent_id: parent.id
      end

      it 'finds nothing' do
        expect(finder.all).to eq([])
      end
    end
  end
end
