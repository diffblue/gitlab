# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DastSiteValidationWorker do
  let_it_be(:dast_site_validation) { create(:dast_site_validation) }

  subject do
    described_class.new.perform(dast_site_validation.id)
  end

  describe '#perform' do
    include_examples 'an idempotent worker' do
      subject do
        perform_multiple([dast_site_validation.id], worker: described_class.new)
      end
    end
  end
end
