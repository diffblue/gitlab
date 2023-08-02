import { mount } from '@vue/test-utils';
import { GlAlert } from '@gitlab/ui';
import ComplianceStandardsAdherenceReport from 'ee/compliance_dashboard/components/standards_adherence_report/report.vue';
import ComplianceStandardsAdherenceTable from 'ee/compliance_dashboard/components/standards_adherence_report/standards_adherence_table.vue';

describe('ComplianceStandardsAdherenceReport component', () => {
  let wrapper;

  const groupPath = 'example-group';

  const findErrorMessage = () => wrapper.findComponent(GlAlert);
  const findAdherencesTable = () => wrapper.findComponent(ComplianceStandardsAdherenceTable);

  const createComponent = () => {
    wrapper = mount(ComplianceStandardsAdherenceReport, {
      propsData: {
        groupPath,
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

    it('renders the standards adherence table component', () => {
      expect(findAdherencesTable().exists()).toBe(true);
    });

    it('passes props to the standards adherence table component', () => {
      expect(findAdherencesTable().props()).toMatchObject({ groupPath });
    });
  });
});
