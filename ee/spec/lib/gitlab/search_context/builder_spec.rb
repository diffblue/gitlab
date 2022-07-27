# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SearchContext::Builder, type: :controller do
  controller(ApplicationController) {}

  subject(:builder) { described_class.new(controller.view_context) }

  describe '#with_group' do
    let(:group) { create(:group) }

    describe '#build!' do
      subject(:context) { builder.with_group(group).build! }

      context 'with epics scope' do
        before do
          allow(controller).to receive(:controller_name).and_return('epics')
        end

        it 'search context returns epics scope' do
          expect(subject.scope).to be('epics')
        end
      end
    end
  end
end
