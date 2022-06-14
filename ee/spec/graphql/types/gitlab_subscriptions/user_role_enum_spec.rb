# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['GitlabSubscriptionsUserRole'] do
  it 'exposes all user roles' do
    expect(described_class.values.keys).to contain_exactly(*%w[GUEST REPORTER DEVELOPER MAINTAINER OWNER])
  end
end
