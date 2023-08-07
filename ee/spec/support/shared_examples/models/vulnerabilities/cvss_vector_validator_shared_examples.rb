# frozen_string_literal: true

RSpec.shared_examples 'model with invalid cvss vector string' do |attribute|
  it { is_expected.to be_invalid }

  it 'reports correct error' do
    expect(subject.errors[attribute]).to include('is not a valid CVSS vector string')
  end
end

RSpec.shared_examples 'model with cvss generic cvss validation' do |attribute|
  context 'when given a value with the wrong type' do
    before do
      allow(subject).to receive(attribute).and_return(Class.new)
    end

    it 'returns an error and raises for dev' do
      expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
        .with(ArgumentError.new("expected #{attribute} to be a ::CvssSuite::Cvss but was Class"))

      subject.validate

      expect(subject.errors[attribute]).to include('cannot be validated due to an unexpected internal state')
    end
  end
end

RSpec.shared_examples 'model with cvss v3 vector validation' do |attribute|
  let(:cvss_version) { '3.1' }
  let(:attack_vector) { 'N' }
  let(:attack_complexity) { 'H' }
  let(:privileges_required) { 'N' }
  let(:user_interaction) { 'N' }
  let(:scope) { 'U' }
  let(:confidentiality) { 'H' }
  let(:integrity) { 'H' }
  let(:availability) { 'H' }

  let(:base_params) do
    {
      CVSS: cvss_version,
      AV: attack_vector,
      AC: attack_complexity,
      PR: privileges_required,
      UI: user_interaction,
      S: scope,
      C: confidentiality,
      I: integrity,
      A: availability
    }
  end

  let(:params) { base_params }

  let(:vector) do
    params.map { |key, value| "#{key}:#{value}" }.join('/')
  end

  before do
    subject[attribute] = vector
    subject.validate
  end

  it_behaves_like 'model with cvss generic cvss validation', attribute

  context 'when validating', :aggregate_failures do
    describe 'version' do
      context 'when version is valid' do
        where(:cvss_version) { %w[3.1 3.0] }

        with_them do
          it { is_expected.to be_valid }
        end
      end

      context 'when version param is invalid' do
        where(:cvss_version) { ['2.0', '???', ''] }

        with_them do
          it_behaves_like 'model with invalid cvss vector string', attribute
        end
      end

      context 'when given a valid cvss v2 vector' do
        let(:vector) { "AV:N/AC:M/Au:N/C:N/I:P/A:N" }

        it { is_expected.to be_invalid }

        it 'reports correct error' do
          expect(subject.errors[attribute]).to include('must use version 3.0 or 3.1')
        end
      end
    end

    describe 'parameters' do
      {
        attack_vector: %w[N A L P],
        attack_complexity: %w[L H],
        privileges_required: %w[N L H],
        user_interaction: %w[N R],
        scope: %w[U C],
        confidentiality: %w[N L H],
        integrity: %w[N L H],
        availability: %w[N L H]
      }.each do |parameter, valid_parameter_values|
        context "when #{parameter} is valid" do
          where(parameter) { valid_parameter_values }

          with_them do
            it { is_expected.to be_valid }
          end
        end

        context "when #{parameter} is invalid" do
          where(parameter) { ['X', '?', '🦊', ''] }

          with_them do
            it_behaves_like 'model with invalid cvss vector string', attribute
          end
        end
      end

      context 'when a parameter is duplicated' do
        let(:vector) { "CVSS:3.1/AV:N/AV:N/AC:H/PR:L/UI:N/S:C/C:N/I:L/A:L" }

        it_behaves_like 'model with invalid cvss vector string', attribute
      end

      context 'when parameter ordering is non-standard' do
        let(:vector) { "CVSS:3.1/A:L/I:L/C:N/S:C/AV:N/UI:N/PR:L/AC:H" }

        # The CVSS specification says that this vector string should be valid,
        # but cvss-suite does not consider it to be so.
        xit { is_expected.to be_valid }
      end

      %i[CVSS AV AC PR UI S C I A].each do |parameter|
        context "when #{parameter} is missing" do
          let(:params) { base_params.except(parameter) }

          it_behaves_like 'model with invalid cvss vector string', attribute
        end
      end

      context 'when vector contains optional metrics' do
        let(:optional_metrics) do
          {
            E: 'H',
            RL: 'U',
            RC: 'C',
            CR: 'H',
            IR: 'H',
            AR: 'H',
            MAV: 'P',
            MAC: 'H',
            MPR: 'H',
            MUI: 'R',
            MS: 'C',
            MC: 'H',
            MI: 'H',
            MA: 'H'
          }
        end

        let(:params) { base_params.merge(optional_metrics) }

        it { is_expected.to be_valid }
      end
    end
  end
end

RSpec.shared_examples 'model with cvss v2 vector validation' do |attribute|
  let(:attack_vector) { 'N' }
  let(:attack_complexity) { 'H' }
  let(:authentication) { 'N' }
  let(:confidentiality) { 'C' }
  let(:integrity) { 'C' }
  let(:availability) { 'C' }

  let(:base_params) do
    {
      AV: attack_vector,
      AC: attack_complexity,
      Au: authentication,
      C: confidentiality,
      I: integrity,
      A: availability
    }
  end

  let(:params) { base_params }

  let(:vector) do
    params.map { |key, value| "#{key}:#{value}" }.join('/')
  end

  before do
    subject[attribute] = vector
    subject.validate
  end

  it_behaves_like 'model with cvss generic cvss validation', attribute

  context 'when validating', :aggregate_failures do
    describe 'version when given a valid cvss v3 vector' do
      where(:vector) do
        [
          "CVSS:3.0/AV:N/AC:H/PR:L/UI:N/S:C/C:N/I:L/A:L",
          "CVSS:3.1/AV:N/AC:H/PR:L/UI:N/S:C/C:N/I:L/A:L"
        ]
      end

      with_them do
        it { is_expected.to be_invalid }

        it 'reports correct error' do
          expect(subject.errors[attribute]).to include('must use version 2')
        end
      end
    end

    describe 'parameters' do
      {
        attack_vector: %w[L A N],
        attack_complexity: %w[H M L],
        authentication: %w[M S N],
        confidentiality: %w[N P C],
        integrity: %w[N P C],
        availability: %w[N P C]
      }.each do |parameter, valid_parameter_values|
        context "when #{parameter} is valid" do
          where(parameter) { valid_parameter_values }

          with_them do
            it { is_expected.to be_valid }
          end
        end

        context "when #{parameter} is invalid" do
          where(parameter) { ['X', '?', '🦊', ''] }

          with_them do
            it_behaves_like 'model with invalid cvss vector string', attribute
          end
        end
      end

      context 'when a parameter is duplicated' do
        let(:vector) { "CVSS:2.0/AN:N/AV:N/AC:M/Au:N/C:N/I:P/A:N" }

        it_behaves_like 'model with invalid cvss vector string', attribute
      end

      %i[AV AC Au C I A].each do |parameter|
        context "when #{parameter} is missing" do
          let(:params) { base_params.except(parameter) }

          it_behaves_like 'model with invalid cvss vector string', attribute
        end
      end

      context 'when vector contains optional metrics' do
        let(:optional_metrics) do
          {
            E: 'H',
            RL: 'U',
            RC: 'C',
            CDP: 'N',
            TD: 'N',
            CR: 'L',
            IR: 'L',
            AR: 'L'
          }
        end

        let(:params) { base_params.merge(optional_metrics) }

        it { is_expected.to be_valid }
      end
    end
  end
end
