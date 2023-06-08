import { shallowMount } from '@vue/test-utils';
import { GlAlert } from '@gitlab/ui';
import ComplianceStandardsAdherenceReport from 'ee/compliance_dashboard/components/standards_adherence_report/report.vue';

describe('ComplianceStandardsAdherenceReport component', () => {
  let wrapper;

  const findErrorMessage = () => wrapper.findComponent(GlAlert);

  const createComponent = () => {
    wrapper = shallowMount(ComplianceStandardsAdherenceReport, {});
  };

  describe('default behavior', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not render an error message', () => {
      expect(findErrorMessage().exists()).toBe(false);
    });
  });
});
