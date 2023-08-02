import { GlAlert, GlTable } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ComplianceStandardsAdherenceTable from 'ee/compliance_dashboard/components/standards_adherence_report/standards_adherence_table.vue';
import { createComplianceAdherencesResponse } from '../../mock_data';

describe('ComplianceStandardsAdherenceTable component', () => {
  let wrapper;

  const adherencesResponse = createComplianceAdherencesResponse();
  const adherences = adherencesResponse.data.group.projectComplianceStandardsAdherence.nodes;

  const findErrorMessage = () => wrapper.findComponent(GlAlert);
  const findStandardsAdherenceTable = () => wrapper.findComponent(GlTable);
  const findTableHeaders = () => findStandardsAdherenceTable().findAll('th');
  const findTableRows = () => findStandardsAdherenceTable().findAll('tr');
  const findFirstTableRow = () => findTableRows().at(1);
  const findFirstTableRowData = () => findFirstTableRow().findAll('td');

  const createComponent = ({ propsData = {}, data = {} } = {}) => {
    wrapper = mountExtended(ComplianceStandardsAdherenceTable, {
      propsData: {
        groupPath: 'example-group',
        ...propsData,
      },
      data() {
        return {
          adherences: {
            list: adherences,
          },
          ...data,
        };
      },
    });
  };

  describe('default behavior', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not render an error message', () => {
      expect(findErrorMessage().exists()).toBe(false);
    });

    it('has the correct table headers', () => {
      const headerTexts = findTableHeaders().wrappers.map((h) => h.text());

      expect(headerTexts).toStrictEqual([
        'Status',
        'Project',
        'Checks',
        'Standard',
        'Last Scanned',
        'Fix Suggestions',
      ]);
    });
  });

  describe('when there are standards adherences', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the table row properly', () => {
      const rowText = findFirstTableRowData().wrappers.map((e) => e.text());

      expect(rowText).toStrictEqual([
        'Success',
        'Example Project',
        'Prevent authors as approvers Have a valid rule that prevents author approved merge requests',
        'GitLab',
        'Jul 1, 2023',
        'View details',
      ]);
    });
  });

  describe('when there are no standards adherences', () => {
    beforeEach(() => {
      createComponent({ data: { adherences: { list: [] } } });
    });

    it('renders the empty table message', () => {
      expect(findStandardsAdherenceTable().text()).toContain(
        ComplianceStandardsAdherenceTable.noStandardsAdherencesFound,
      );
    });
  });
});
