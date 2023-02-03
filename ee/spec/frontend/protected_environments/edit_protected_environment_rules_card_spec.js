import { mountExtended } from 'helpers/vue_test_utils_helper';
import EditProtectedEnvironmentRulesCard from 'ee/protected_environments/edit_protected_environment_rules_card.vue';

const DEFAULT_ENVIRONMENT = {
  deploy_access_levels: [{ access_level: 30 }, { group_id: 1 }, { user_id: 1 }],
};

const generateText = (rule) => {
  const [access] = Object.entries(rule);
  return access.join('-');
};

describe('ee/protected_environments/edit_protected_environment_rules_card.vue', () => {
  let wrapper;

  const createComponent = ({
    ruleKey = 'deploy_access_levels',
    loading = false,
    environment = DEFAULT_ENVIRONMENT,
    scopedSlots = {},
  } = {}) =>
    mountExtended(EditProtectedEnvironmentRulesCard, {
      propsData: {
        ruleKey,
        loading,
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
});
