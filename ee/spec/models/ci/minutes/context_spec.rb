# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Minutes::Context do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }

  describe 'delegation' do
    subject { described_class.new(project, group) }

    it { is_expected.to delegate_method(:shared_runners_minutes_limit_enabled?).to(:namespace) }
    it { is_expected.to delegate_method(:name).to(:namespace).with_prefix }
  end
end
