# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupHookPolicy do
  let_it_be(:user) { create(:user) }

  let(:hook) { create(:group_hook) }

  subject(:policy) { described_class.new(user, hook) }

  context 'when the user is not an owner' do
    before do
      hook.group.add_maintainer(user)
    end

    it "cannot destroy web-hooks" do
      expect(policy).to be_disallowed(:destroy_web_hook)
    end
  end

  context 'when the user is an owner' do
    before do
      hook.group.add_owner(user)
    end

    it "can destroy web-hooks" do
      expect(policy).to be_allowed(:destroy_web_hook)
    end
  end
end
