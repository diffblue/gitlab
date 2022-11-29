# frozen_string_literal: true

# This shared example needs a `group` variable to be set.
RSpec.shared_examples 'applying ip restriction for group' do
  before do
    allow(Gitlab::IpAddressState).to receive(:current).and_return('192.168.0.2')
    stub_licensed_features(group_ip_restriction: true)
  end

  context 'in group without restriction' do
    it_behaves_like 'returning response status', :ok
  end

  context 'in group with restriction' do
    before do
      create(:ip_restriction, group: group, range: range)
    end

    context 'with address within the range' do
      let(:range) { '192.168.0.0/24' }

      it_behaves_like 'returning response status', :ok
    end

    context 'with address outside the range' do
      let(:range) { '10.0.0.0/8' }

      it_behaves_like 'returning response status', :not_found
    end
  end
end
