import { mountExtended } from 'helpers/vue_test_utils_helper';
import PolicyRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_result_policy/policy_rule_builder_v2.vue';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import { emptyBuildRule } from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib/rules';

describe('PolicyRuleBuilder V2', () => {
  let wrapper;

  const factory = (propsData = {}, provide = {}) => {
    wrapper = mountExtended(PolicyRuleBuilder, {
      propsData: {
        initRule: emptyBuildRule(),
        ...propsData,
      },
      provide: {
        namespaceId: '1',
        namespaceType: NAMESPACE_TYPES.PROJECT,
        ...provide,
      },
    });
  };

  const findDeleteBtn = () => wrapper.findByTestId('remove-rule');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('initial rendering', () => {
    beforeEach(() => {
      factory();
    });

    it('renders the delete button', () => {
      expect(findDeleteBtn().exists()).toBe(true);
    });

    it('emits the remove event when removing the rule', async () => {
      await findDeleteBtn().vm.$emit('click');

      expect(wrapper.emitted().remove).toHaveLength(1);
    });
  });
});
