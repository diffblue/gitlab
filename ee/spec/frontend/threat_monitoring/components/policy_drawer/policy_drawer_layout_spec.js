import PolicyDrawerLayout from 'ee/threat_monitoring/components/policy_drawer/policy_drawer_layout.vue';
import {
  DEFAULT_DESCRIPTION_LABEL,
  ENABLED_LABEL,
  NOT_ENABLED_LABEL,
} from 'ee/threat_monitoring/components/policy_drawer/constants';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockScanExecutionPolicy } from '../../mocks/mock_data';

describe('PolicyDrawerLayout component', () => {
  let wrapper;

  const DESCRIPTION = 'This policy enforces pipeline configuration to have a job with DAST scan';
  const SUMMARY = 'Summary';
  const TYPE = 'Scan Execution';

  const findCustomDescription = () => wrapper.findByTestId('custom-description-text');
  const findDefaultDescription = () => wrapper.findByTestId('default-description-text');
  const findEnabledText = () => wrapper.findByTestId('enabled-status-text');
  const findNotEnabledText = () => wrapper.findByTestId('not-enabled-status-text');
  const findSummaryText = () => wrapper.findByTestId('summary-text');
  const findTypeText = () => wrapper.findByTestId('policy-type');

  const componentStatusText = (status) => (status ? 'does' : 'does not');

  const factory = (propsData = {}) => {
    wrapper = shallowMountExtended(PolicyDrawerLayout, {
      propsData: {
        type: TYPE,
        ...propsData,
      },
      scopedSlots: {
        summary: `<span data-testid="summary-text">Summary</span>`,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each`
    context                 | props                                                            | enabled  | hasDescription
    ${'enabled policy'}     | ${{ policy: mockScanExecutionPolicy, description: DESCRIPTION }} | ${true}  | ${true}
    ${'not enabled policy'} | ${{ policy: { ...mockScanExecutionPolicy, enabled: false } }}    | ${false} | ${false}
  `('$context', ({ enabled, hasDescription, props }) => {
    beforeEach(() => {
      factory(props);
    });

    it.each`
      component                | status                                  | finder                    | exists             | text
      ${'type text'}           | ${'does'}                               | ${findTypeText}           | ${true}            | ${TYPE}
      ${'summary text'}        | ${'does'}                               | ${findSummaryText}        | ${true}            | ${SUMMARY}
      ${'custom description'}  | ${componentStatusText(hasDescription)}  | ${findCustomDescription}  | ${hasDescription}  | ${DESCRIPTION}
      ${'default description'} | ${componentStatusText(!hasDescription)} | ${findDefaultDescription} | ${!hasDescription} | ${DEFAULT_DESCRIPTION_LABEL}
      ${'enabled text'}        | ${componentStatusText(enabled)}         | ${findEnabledText}        | ${enabled}         | ${ENABLED_LABEL}
      ${'not enabled text'}    | ${componentStatusText(!enabled)}        | ${findNotEnabledText}     | ${!enabled}        | ${NOT_ENABLED_LABEL}
    `('$status render the $component', ({ exists, finder, text }) => {
      const component = finder();
      expect(component.exists()).toBe(exists);
      if (exists) {
        expect(component.text()).toBe(text);
      }
    });
  });
});
