# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe RemoteDevelopment::MessageSupport, feature_category: :remote_development do
  let(:object) { Object.new.extend(described_class) }

  describe '.generate_error_response_from_message' do
    context 'for an unsupported context which is not pattern matched' do
      let(:message) { RemoteDevelopment::Message.new(context: { unsupported: 'unmatched' }) }

      it 'raises an error' do
        expect { object.generate_error_response_from_message(message: message, reason: :does_not_matter) }
          .to raise_error(/Unexpected message context/)
      end
    end
  end
end
