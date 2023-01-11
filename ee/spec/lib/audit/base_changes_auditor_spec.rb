# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Audit::BaseChangesAuditor do
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:group) { build_stubbed(:group) }
  let_it_be(:project) { build_stubbed(:project, group: group) }

  subject { described_class.new(user, project) }

  describe '#attributes_from_auditable_model' do
    it { expect { subject.send(:attributes_from_auditable_model, nil) }.to raise_error(NotImplementedError) }
  end
end
