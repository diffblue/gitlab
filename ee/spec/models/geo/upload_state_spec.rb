# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::UploadState, :geo, type: :model do
  it { is_expected.to belong_to(:upload).inverse_of(:upload_state) }
end
