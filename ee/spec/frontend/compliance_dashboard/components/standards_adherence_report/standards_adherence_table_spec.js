import { GlAlert, GlTable } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ComplianceStandardsAdherenceTable from 'ee/compliance_dashboard/components/standards_adherence_report/standards_adherence_table.vue';
import { createComplianceAdherencesResponse } from '../../mock_data';

describe('ComplianceStandardsAdherenceTable component', () => {
  let wrapper;

  const adherencesResponse = (checkName) => createComplianceAdherencesResponse({ checkName });
  const adherences = (checkName) =>
    adherencesResponse(checkName).data.group.projectComplianceStandardsAdherence.nodes;

  const findErrorMessage = () => wrapper.findComponent(GlAlert);
  const findStandardsAdherenceTable = () => wrapper.findComponent(GlTable);
  const findTableHeaders = () => findStandardsAdherenceTable().findAll('th');
  const findTableRows = () => findStandardsAdherenceTable().findAll('tr');
  const findFirstTableRow = () => findTableRows().at(1);
  const findFirstTableRowData = () => findFirstTableRow().findAll('td');

  const createComponent = ({
    propsData = {},
    data = {},
    checkName = 'AT_LEAST_TWO_APPROVALS',
  } = {}) => {
    wrapper = mountExtended(ComplianceStandardsAdherenceTable, {
      propsData: {
        groupPath: 'example-group',
        ...propsData,
      },
      data() {
        return {
          adherences: {
            list: adherences(checkName),
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

  describe('when there are standards adherence checks available', () => {
    describe('when check is `PREVENT_APPROVAL_BY_MERGE_REQUEST_AUTHOR`', () => {
      beforeEach(() => {
        createComponent({ checkName: 'PREVENT_APPROVAL_BY_MERGE_REQUEST_AUTHOR' });
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

    describe('when check is `PREVENT_APPROVAL_BY_MERGE_REQUEST_COMMITTERS`', () => {
      beforeEach(() => {
        createComponent({ checkName: 'PREVENT_APPROVAL_BY_MERGE_REQUEST_COMMITTERS' });
      });

      it('renders the table row properly', () => {
        const rowText = findFirstTableRowData().wrappers.map((e) => e.text());

        expect(rowText).toStrictEqual([
          'Success',
          'Example Project',
          'Prevent committers as approvers Have a valid rule that prevents merge requests approved by committers',
          'GitLab',
          'Jul 1, 2023',
          'View details',
        ]);
      });
    });

    describe('when check is `AT_LEAST_TWO_APPROVALS`', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders the table row properly', () => {
        const rowText = findFirstTableRowData().wrappers.map((e) => e.text());

        expect(rowText).toStrictEqual([
          'Success',
          'Example Project',
          'At least two approvals Have a valid rule that requires any merge request to have more than two approvals',
          'GitLab',
          'Jul 1, 2023',
          'View details',
        ]);
      });
    });
  });

  describe('when there are no standards adherence checks available', () => {
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
