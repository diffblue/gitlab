# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Licenses::DestroyService do
  let(:license) { create(:license) }

  let_it_be(:user) { create(:admin) }

  def destroy_with(user)
    described_class.new(license, user).execute
  end

  context 'when admin mode is enabled', :enable_admin_mode do
    it 'destroys a license' do
      destroy_with(user)

      expect(License.where(id: license.id)).not_to exist
    end

    context 'with cloud license' do
      let(:license) { create(:license, cloud_licensing_enabled: true, plan: License::ULTIMATE_PLAN) }

      it 'destroys a license' do
        destroy_with(user)

        expect(License.where(id: license.id)).not_to exist
      end
    end
  end

  context 'when admin mode is disabled' do
    it 'raises not allowed error' do
      expect { destroy_with(user) }.to raise_error(::Gitlab::Access::AccessDeniedError)
    end
  end

  it 'raises an error if license is nil' do
    expect { described_class.new(nil, user).execute }.to raise_error ActiveRecord::RecordNotFound
  end

  it 'raises an error if the user is not an admin' do
    expect { destroy_with(create(:user)) }.to raise_error Gitlab::Access::AccessDeniedError
  end
end
