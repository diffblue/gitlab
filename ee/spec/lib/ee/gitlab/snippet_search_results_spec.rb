# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::SnippetSearchResults do
  let_it_be(:snippet) { create(:snippet, title: 'foo', description: 'foo') }

  let(:user) { snippet.author }
  let(:com_value) { true }

  subject { described_class.new(user, 'foo').objects('snippet_titles') }

  before do
    allow(Gitlab).to receive(:com?).and_return(com_value)
  end

  context 'when all requirements are met' do
    it 'calls the finder with the restrictive scope' do
      expect(SnippetsFinder).to receive(:new).with(user, { authorized_and_user_personal: true }).and_call_original

      subject
    end
  end

  context 'when not in Gitlab.com' do
    let(:com_value) { false }

    it 'calls the finder with the restrictive scope' do
      expect(SnippetsFinder).to receive(:new).with(user, {}).and_call_original

      subject
    end
  end
end
