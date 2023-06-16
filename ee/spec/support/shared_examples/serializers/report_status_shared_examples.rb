# frozen_string_literal: true

RSpec.shared_examples 'report list' do
  describe '#as_json' do
    let(:entity) do
      described_class.represent(items, build: ci_build, request: request)
    end

    let(:request) { double('request') }

    let_it_be(:project) { create(:project, :repository, :private) }
    let_it_be(:developer) { create(:user) }

    subject { entity.as_json }

    before do
      project.add_developer(developer)
      allow(request).to receive(:project).and_return(project)
      allow(request).to receive(:user).and_return(user)
    end

    context 'with success build' do
      let(:user) { developer }
      let(:ci_build) { create(:ee_ci_build, :success) }

      context 'with provided items' do
        let(:items) { collection }

        it 'has array of items with status ok' do
          job_path = "/#{project.full_path}/builds/#{ci_build.id}"

          expect(subject[name]).to be_kind_of(Array)
          expect(subject[:report][:status]).to eq(:ok)
          expect(subject[:report][:job_path]).to eq(job_path)
          expect(subject[:report][:generated_at]).to eq(ci_build.finished_at)
        end
      end

      context 'with no items' do
        let(:user) { developer }
        let(:items) { [] }

        it 'has empty array of items with status no_items' do
          job_path = "/#{project.full_path}/builds/#{ci_build.id}"

          expect(subject[name].length).to eq(0)
          expect(subject[:report][:status]).to eq(no_items_status)
          expect(subject[:report][:job_path]).to eq(job_path)
        end
      end
    end

    context 'with failed build' do
      let(:ci_build) { create(:ee_ci_build, :failed) }
      let(:items) { [] }

      context 'with authorized user' do
        let(:user) { developer }

        it 'has job_path with status failed_job' do
          expect(subject[:report][:status]).to eq(:job_failed)
          expect(subject[:report]).to include(:job_path)
        end
      end

      context 'without authorized user' do
        let(:user) { create(:user) }

        it 'has only status failed_job' do
          expect(subject[:report][:status]).to eq(:job_failed)
          expect(subject[:report]).not_to include(:job_path)
          expect(subject[:report]).not_to include(:generated_at)
        end
      end
    end

    context 'with no build' do
      let(:user) { developer }
      let(:ci_build) { nil }
      let(:items) { [] }

      it 'has status job_not_set_up and no job_path' do
        expect(subject[:report][:status]).to eq(:job_not_set_up)
        expect(subject[:report][:job_path]).not_to be_present
        expect(subject[:report][:generated_at]).not_to be_present
      end

      context 'without an associated project' do
        before do
          allow(request).to receive(:project).and_return(nil)
        end

        it 'returns a no_items status' do
          expect(subject[:report][:status]).to eq(no_items_status)
        end

        context 'with items are present' do
          let(:items) { collection }

          it 'returns a ok status' do
            expect(subject[:report][:status]).to eq(:ok)
          end
        end
      end
    end
  end
end
