# frozen_string_literal: true

RSpec.shared_examples_for 'contribution analytics charts configuration' do
  def response_as_hash
    Gitlab::Json.parse(response.body)
  end

  def include_dora_charts?
    response_as_hash.any? do |_, dashboard|
      dashboard['charts'].any? do |chart|
        chart['query']['data_source'] == 'dora'
      end
    end
  end

  context 'when user does not have permissions to access all charts' do
    let_it_be(:user) { create(:user).tap { |u| insights_entity.add_guest(u) } }

    it 'removes forbidden charts from configuration' do
      run_request

      expect(include_dora_charts?).to be(false)
    end
  end

  context 'when user have permissions to access all charts' do
    let_it_be(:user) { create(:user).tap { |u| insights_entity.add_reporter(u) } }

    it 'does not remove charts from configuration' do
      run_request

      expect(include_dora_charts?).to be(true)
    end
  end
end
