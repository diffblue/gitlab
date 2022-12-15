# frozen_string_literal: true

# When using this shared example, with_project_association variable
# needs to be defined in the current context as false or true.
# Also, record1 and record2 should be declared in that context too.
RSpec.shared_examples 'a model that implements the search method' do
  let_it_be(:project1) do
    create(:project, name: 'project_1_name', path: 'project_1_path', description: 'project_desc_1')
  end

  let_it_be(:project2) do
    create(:project, name: 'project_2_name', path: 'project_2_path', description: 'project_desc_2')
  end

  context 'when search query is empty' do
    it 'returns all records' do
      result = described_class.search('')

      expect(result).to contain_exactly(record1, record2)
    end
  end

  context 'when search query is not empty' do
    context 'without matches' do
      it 'filters all records' do
        result = described_class.search('something_that_does_not_exist')

        expect(result).to be_empty
      end
    end

    context 'with matches by attributes' do
      where(:searchable_attribute) do
        if described_class.const_defined?(:EE_SEARCHABLE_ATTRIBUTES)
          described_class::EE_SEARCHABLE_ATTRIBUTES
        else
          []
        end
      end

      before do
        skip if searchable_attribute.empty?

        # Use update_column to bypass attribute validations like regex formatting, checksum, etc.
        record1.update_column(searchable_attribute, 'any_keyword')
      end

      with_them do
        it do
          result = described_class.search('any_keyword')

          expect(result).to contain_exactly(record1)
        end
      end
    end

    context 'with matches by project association' do
      before do
        skip unless with_project_association
      end

      it 'filters by project path' do
        result = described_class.search('project_1_PATH')

        expect(result).to contain_exactly(record1)
      end

      it 'filters by project name' do
        result = described_class.search('Project_2_NAME')

        expect(result).to contain_exactly(record2)
      end

      it 'filters project description' do
        result = described_class.search('Project_desc')

        expect(result).to contain_exactly(record1, record2)
      end
    end
  end
end
