# frozen_string_literal: true

RSpec.shared_examples 'a date range error is returned' do
  using RSpec::Parameterized::TableSyntax

  where(:created_after, :created_before) do
    '2021-01-01' | '2021-02-02'
    '2022-01-31' | nil
  end
  with_them do
    it 'returns an error' do
      subject

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(flash[:alert]).to eq 'Date range limited to 31 days'
    end
  end
end
