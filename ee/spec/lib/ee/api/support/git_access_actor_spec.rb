# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Support::GitAccessActor do
  describe '.from_params' do
    context 'when passing a Kerberos principal' do
      it 'finds the user based on a principal' do
        principal = "test@TEST.TEST"
        user = create(:omniauth_user, provider: :kerberos, extern_uid: principal)

        expect(described_class.from_params({ krb5principal: principal }).user).to eq(user)
      end
    end
  end
end
