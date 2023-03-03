import { GlButton } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { DEPLOYER_RULE_KEY } from 'ee/protected_environments/constants';
import EditProtectedEnvironmentRulesCard from 'ee/protected_environments/edit_protected_environment_rules_card.vue';
import { DEVELOPER_ACCESS_LEVEL } from './constants';

const DEFAULT_ENVIRONMENT = {
  deploy_access_levels: [{ access_level: DEVELOPER_ACCESS_LEVEL }, { group_id: 1 }, { user_id: 1 }],
};

const generateText = (rule) => {
  const [access] = Object.entries(rule);
  return access.join('-');
};

describe('ee/protected_environments/edit_protected_environment_rules_card.vue', () => {
  let wrapper;

  const createComponent = ({
    ruleKey = DEPLOYER_RULE_KEY,
    loading = false,
    addButtonText = 'Add Deploy Rule',
    environment = DEFAULT_ENVIRONMENT,
    scopedSlots = {},
  } = {}) =>
    mountExtended(EditProtectedEnvironmentRulesCard, {
      propsData: {
        ruleKey,
        loading,
        addButtonText,
        environment,
      },
      scopedSlots,
    });

  describe('rule slot', () => {
    beforeEach(() => {
      wrapper = createComponent({
        scopedSlots: {
          rule({ rule }) {
            const testid = generateText(rule);
            return this.$createElement('div', { id: testid }, [testid]);
          },
        },
      });
    });

    it('shows one slot per rule', () => {
      DEFAULT_ENVIRONMENT.deploy_access_levels.forEach((rule) =>
        expect(wrapper.text()).toContain(generateText(rule)),
      );
    });
  });

  describe('card header slot', () => {
    beforeEach(() => {
      wrapper = createComponent({
        scopedSlots: {
          'card-header': '<span data-testid="slot">hello</span>',
        },
      });
    });

    it('displays the slot', () => {
      expect(wrapper.findByTestId('slot').text()).toBe('hello');
    });
  });

  describe('add button', () => {
    let text;
    let loading;
    let button;

    beforeEach(() => {
      text = 'Add Approval Rule';
      loading = true;
      wrapper = createComponent({ addButtonText: text, loading });
      button = wrapper.findComponent(GlButton);
    });

    it('passes the text to the button', () => {
      expect(button.text()).toBe(text);
    });

    it('passes the loading state to the button', () => {
      expect(button.props('loading')).toBe(loading);
    });

    it('emits the addRule event when clicked', () => {
      button.vm.$emit('click');

      expect(wrapper.emitted('addRule')).toEqual([
        [{ environment: DEFAULT_ENVIRONMENT, ruleKey: DEPLOYER_RULE_KEY }],
      ]);
    });
  });
});
