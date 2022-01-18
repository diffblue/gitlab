# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../../lib/ee/gitlab/patch/draw_route'

RSpec.describe Gitlab::Patch::DrawRoute do
  subject do
    Class.new do
      include Gitlab::Patch::DrawRoute

      def route_path(route_name)
        File.expand_path("../../../../../#{route_name}", __dir__)
      end
    end.new
  end

  before do
    allow(subject).to receive(:instance_eval)
  end

  it 'evaluates EE only routes' do
    subject.draw(:oauth)

    expect(subject).to have_received(:instance_eval)
      .with(File.read(subject.route_path('ee/config/routes/oauth.rb')))
      .once

    expect(subject).to have_received(:instance_eval)
      .once
  end

  it 'evaluates CE and EE routes' do
    subject.draw(:admin)

    expect(subject).to have_received(:instance_eval)
      .with(File.read(subject.route_path('config/routes/admin.rb')))
      .once

    expect(subject).to have_received(:instance_eval)
      .with(File.read(subject.route_path('ee/config/routes/admin.rb')))
      .once
  end

  it 'raises an error when nothing is drawn' do
    expect { subject.draw(:non_existing) }
      .to raise_error(described_class::RoutesNotFound)
  end
end
