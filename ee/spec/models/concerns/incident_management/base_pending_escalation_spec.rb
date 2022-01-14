# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::BasePendingEscalation do
  let(:klass) do
    Class.new(ApplicationRecord) do
      include IncidentManagement::BasePendingEscalation

      self.table_name = 'incident_management_pending_alert_escalations'
    end
  end

  subject(:instance) { klass.new }

  describe '.class_for_check_worker' do
    it 'must be implemented' do
      expect { klass.class_for_check_worker }.to raise_error(NotImplementedError)
    end
  end

  describe '#escalatable' do
    it 'must be implemented' do
      expect { instance.escalatable }.to raise_error(NotImplementedError)
    end
  end

  describe '#type' do
    it 'must be implemented' do
      expect { instance.type }.to raise_error(NotImplementedError)
    end
  end
end
