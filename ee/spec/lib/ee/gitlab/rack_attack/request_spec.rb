# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RackAttack::Request do
  using RSpec::Parameterized::TableSyntax

  let(:path) { '/' }
  let(:env) { {} }
  let(:request) do
    ::Rack::Attack::Request.new(
      env.reverse_merge(
        'REQUEST_METHOD' => 'GET',
        'PATH_INFO' => path,
        'rack.input' => StringIO.new
      )
    )
  end

  describe '#should_be_skipped?' do
    where(
      super_value: [true, false],
      geo: [true, false]
    )

    with_them do
      it 'returns true if any condition is true' do
        allow(request).to receive(:api_internal_request?).and_return(super_value)
        allow(request).to receive(:health_check_request?).and_return(super_value)
        allow(request).to receive(:container_registry_event?).and_return(super_value)
        allow(request).to receive(:geo?).and_return(geo)

        expect(request.should_be_skipped?).to be(super_value || geo)
      end
    end
  end

  describe '#geo?' do
    subject { request.geo? }

    where(:env, :geo_auth_attempt, :expected) do
      {}                                   | false | false
      {}                                   | true  | false
      { 'HTTP_AUTHORIZATION' => 'secret' } | false | false
      { 'HTTP_AUTHORIZATION' => 'secret' } | true  | true
    end

    with_them do
      before do
        allow(Gitlab::Geo::JwtRequestDecoder).to receive(:geo_auth_attempt?).and_return(geo_auth_attempt)
      end

      it { is_expected.to be(expected) }
    end
  end
end
