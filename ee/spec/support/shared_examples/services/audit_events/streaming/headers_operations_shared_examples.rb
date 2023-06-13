# frozen_string_literal: true

RSpec.shared_examples 'header creation validation errors' do
  let(:expected_errors) { ["Key can't be blank", "Value can't be blank"] }

  it 'has an array of errors in the response' do
    expect(response).to be_error
    expect(response.errors).to match_array expected_errors
  end
end

RSpec.shared_examples 'header creation successful' do
  it 'has the header in the response payload' do
    expect(response).to be_success
    expect(response.payload[:header].key).to eq 'a_key'
    expect(response.payload[:header].value).to eq 'a_value'
  end

  it 'creates header for destination' do
    expect { response }
      .to change { destination.headers.count }.by(1)

    destination.headers.reload
    header = destination.headers.last

    expect(header.key).to eq('a_key')
    expect(header.value).to eq('a_value')
  end
end

RSpec.shared_examples 'header updation' do
  context 'when header updation is successful' do
    it 'has the header in the response payload' do
      expect(response).to be_success
      expect(response.payload[:header].key).to eq 'new'
      expect(response.payload[:header].value).to eq 'new'
    end

    it 'updates the header' do
      expect(response).to be_success
      expect(header.reload.key).to eq 'new'
      expect(header.value).to eq 'new'
    end
  end

  context 'when header updation is unsuccessful' do
    let(:params) do
      {
        header: header,
        key: '',
        value: 'new'
      }
    end

    it 'does not update the header' do
      expect { subject }.not_to change { header.reload.key }
      expect(header.value).to eq 'old'
    end

    it 'has an error response' do
      expect(response).to be_error
      expect(response.errors)
        .to match_array ["Key can't be blank"]
    end
  end
end
