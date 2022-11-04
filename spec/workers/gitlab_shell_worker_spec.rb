# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabShellWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    describe 'all other commands' do
      it 'delegates them to Gitlab::Shell' do
        expect_next_instance_of(Gitlab::Shell) do |instance|
          expect(instance).to receive(:foo).with('bar', 'baz')
        end

        worker.perform('foo', 'bar', 'baz')
      end
    end
  end
end
