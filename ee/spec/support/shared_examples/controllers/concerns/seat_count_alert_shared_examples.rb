# frozen_string_literal: true

RSpec.shared_examples 'seat count alert' do
  let(:seat_count_data) do
    {
      namespace: namespace.root_ancestor,
      remaining_seat_count: 1,
      seats_in_use: 9,
      total_seat_count: 10
    }
  end

  context 'when the namespace qualifies for the alert' do
    it 'sets the seat_count_data' do
      allow_next_instance_of(GitlabSubscriptions::Reconciliations::CalculateSeatCountDataService) do |service|
        allow(service).to receive(:execute).and_return(seat_count_data)
      end

      subject

      expect(assigns(:seat_count_data)).to eq seat_count_data
    end
  end

  context 'when the namespace does not qualify for the alert' do
    it 'sets the seat_count_data to nil' do
      allow_next_instance_of(GitlabSubscriptions::Reconciliations::CalculateSeatCountDataService) do |service|
        allow(service).to receive(:execute).and_return(nil)
      end

      subject

      expect(assigns(:seat_count_data)).to be_nil
    end
  end
end
