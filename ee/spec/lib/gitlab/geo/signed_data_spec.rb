# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo::SignedData, feature_category: :geo_replication do
  using RSpec::Parameterized::TableSyntax
  include EE::GeoHelpers

  let_it_be_with_reload(:geo_node) { create(:geo_node) }

  let(:validity_period) { 42.minutes }
  let(:include_disabled_nodes) { false }
  let(:klass_args) { {} }
  let(:data) { { input: 123, other_input: 'string value' } }
  let(:signed_data) { described_class.new(geo_node: geo_node).sign_and_encode_data(data) }

  before do
    stub_current_geo_node(geo_node)
  end

  describe '#sign_and_encode_data' do
    subject(:returned_data) { described_class.new(**klass_args).sign_and_encode_data(data) }

    let(:klass_args) { { geo_node: geo_node } }
    let(:parsed_access_key) { returned_data.split(':').first }
    let(:jwt) { JWT.decode(returned_data.split(':').second, geo_node.secret_access_key) }
    let(:decoded_data) { Gitlab::Json.parse(jwt.first['data']) }

    context 'when data is not set' do
      let(:data) { nil }

      it 'does not set the data attribute' do
        expect(decoded_data).to be_nil
      end
    end

    context 'when geo_node is not set' do
      let(:geo_node) { nil }

      it 'raises a GeoNodeNotFoundError error' do
        expect { subject }.to raise_error(::Gitlab::Geo::GeoNodeNotFoundError)
      end
    end

    it 'formats the signed data properly' do
      expect(parsed_access_key).to eq(geo_node.access_key)

      decoded_data.deep_symbolize_keys!
      expect(decoded_data).to eq(data)
    end

    it 'defaults to 1-minute expiration time', :freeze_time do
      expect(jwt.first['exp']).to eq((Time.zone.now + 1.minute).to_i)
    end

    context 'with custom validity period' do
      let(:klass_args) { { geo_node: geo_node, validity_period: 42.minutes } }

      it 'uses that expiration time', :freeze_time do
        expect(jwt.first['exp']).to eq((Time.zone.now + 42.minutes).to_i)
      end
    end
  end

  describe '#decode_data' do
    subject(:returned_data) { described_class.new(**klass_args).decode_data(signed_data) }

    it { is_expected.to eq(data) }

    context 'when data is not set' do
      let(:signed_data) { nil }

      it { is_expected.to be_nil }
    end

    context 'for disabled nodes' do
      before_all do
        geo_node.update_attribute(:enabled, false)
      end

      after(:all) do
        geo_node.update_attribute(:enabled, true)
      end

      context 'fails to decode for disabled nodes by default' do
        it { is_expected.to be_nil }
      end

      context 'when include_disabled_nodes is set to false' do
        let(:klass_args) { { include_disabled_nodes: false } }

        it { is_expected.to be_nil }
      end

      context 'when include_disabled_nodes is set to true' do
        let(:klass_args) { { include_disabled_nodes: true } }

        it { is_expected.to eq(data) }
      end
    end

    context 'with the wrong key' do
      before do
        # ensure this generated before changing the key
        signed_data

        geo_node.update_attribute(:secret_access_key, 'invalid')
      end

      it { is_expected.to be_nil }
    end

    context 'time checks' do
      before do
        signed_data
      end

      it 'successfully decodes when clocks are off' do
        travel_to(30.seconds.ago) { expect(subject).to eq(data) }
      end

      it 'raises an error after expiring' do
        travel_to(2.minutes.from_now) { expect { subject }.to raise_error(Gitlab::Geo::InvalidSignatureTimeError) }
      end

      it 'raises an error when clocks are not in sync' do
        travel_to(2.minutes.ago) { expect { subject }.to raise_error(Gitlab::Geo::InvalidSignatureTimeError) }
      end
    end

    context 'JWT raised errors' do
      context 'surfaces expected errors' do
        where(:raised_error, :expected_error) do
          JWT::ImmatureSignature | Gitlab::Geo::InvalidSignatureTimeError
          JWT::ExpiredSignature  | Gitlab::Geo::InvalidSignatureTimeError
        end

        with_them do
          it 'raises expected error' do
            expect(JWT).to receive(:decode).and_raise(raised_error)

            expect { subject }.to raise_error(expected_error)
          end
        end
      end

      context 'for a decoding error' do
        before do
          allow(JWT).to receive(:decode).and_raise(JWT::DecodeError)
        end

        it { is_expected.to be_nil }
      end
    end
  end
end
