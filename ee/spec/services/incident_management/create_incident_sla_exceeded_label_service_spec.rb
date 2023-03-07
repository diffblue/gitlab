# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::CreateIncidentSlaExceededLabelService, feature_category: :incident_management do
  it_behaves_like 'incident management label service'
end
