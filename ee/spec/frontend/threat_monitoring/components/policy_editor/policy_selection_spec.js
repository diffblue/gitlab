import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { POLICY_TYPE_COMPONENT_OPTIONS } from 'ee/threat_monitoring/components/constants';
import PolicySelection from 'ee/threat_monitoring/components/policy_editor/policy_selection.vue';

describe('PolicySelection component', () => {
  let wrapper;

  const factory = () => {
    wrapper = shallowMountExtended(PolicySelection, {
      stubs: { GlCard: true },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each`
    id                                                          | title
    ${POLICY_TYPE_COMPONENT_OPTIONS.container.urlParameter}     | ${PolicySelection.i18n.networkPolicyTitle}
    ${POLICY_TYPE_COMPONENT_OPTIONS.scanResult.urlParameter}    | ${PolicySelection.i18n.scanResultPolicyTitle}
    ${POLICY_TYPE_COMPONENT_OPTIONS.scanExecution.urlParameter} | ${PolicySelection.i18n.scanExecutionPolicyTitle}
  `('selection card: $title', ({ id, title }) => {
    beforeEach(() => {
      factory();
    });

    it(`should display the title`, () => {
      expect(wrapper.findByText(title).exists()).toBe(true);
    });

    it(`should have a button to link to the second page`, () => {
      expect(wrapper.findByTestId(`select-policy-${id}`).attributes('href')).toContain(
        `?type=${id}`,
      );
    });
  });
});
