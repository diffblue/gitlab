# frozen_string_literal: true

module QA
  RSpec.shared_examples 'a QA scenario class' do
    let(:scenario) { class_spy('Runtime::Scenario') }
    let(:runner) { class_spy('Specs::Runner') }
    let(:release) { class_spy('Runtime::Release') }
    let(:feature) { class_spy('Runtime::Feature') }

    let(:args) { { gitlab_address: 'http://gitlab_address' } }
    let(:named_options) { %w[--address http://gitlab_address] }
    let(:tags) { [] }
    let(:options) { %w[path1 path2] }

    before do
      stub_const('QA::Specs::Runner', runner)
      stub_const('QA::Runtime::Release', release)
      stub_const('QA::Runtime::Scenario', scenario)
      stub_const('QA::Runtime::Feature', feature)

      allow(scenario).to receive(:attributes).and_return(args)
      allow(runner).to receive(:perform).and_yield(runner)
    end

    it 'responds to perform' do
      expect(subject).to respond_to(:perform)
    end

    it 'performs before hooks only once' do
      subject.perform(args)

      expect(release).to have_received(:perform_before_hooks).once
    end

    it 'sets tags on runner' do
      subject.perform(args)

      expect(runner).to have_received(:tags=).with(tags)
    end

    context 'with RSpec options' do
      it 'sets options on runner' do
        subject.perform(args, *options)

        expect(runner).to have_received(:options=).with(options)
      end
    end

    context 'with named command-line options' do
      it 'converts options to attributes' do
        described_class.launch!(named_options)

        args do |k, v|
          expect(scenario).to have_received(:define).with(k, v)
        end
      end

      it 'raises an error if the option is invalid' do
        expect { described_class.launch!(['--foo']) }.to raise_error(OptionParser::InvalidOption)
      end

      it 'passes on options after --' do
        expect(described_class).to receive(:perform).with(args, *%w[--tag quarantine])

        described_class.launch!(named_options.push(*%w[-- --tag quarantine]))
      end
    end
  end
end
