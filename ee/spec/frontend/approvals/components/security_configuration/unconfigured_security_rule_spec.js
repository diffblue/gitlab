import { GlSprintf, GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import UnconfiguredSecurityRule from 'ee/approvals/components/security_configuration/unconfigured_security_rule.vue';
import { COVERAGE_CHECK_NAME } from 'ee/approvals/constants';

Vue.use(Vuex);

describe('UnconfiguredSecurityRule component', () => {
  let wrapper;
  let description;

  const findDescription = () => wrapper.findComponent(GlSprintf);
  const findButton = () => wrapper.findComponent(GlButton);

  const coverageCheckRule = {
    name: COVERAGE_CHECK_NAME,
    description: 'coverage-check description with enable button',
    docsPath: 'docs/coverage-check',
  };

  const createWrapper = (props = {}, options = {}) => {
    wrapper = mount(UnconfiguredSecurityRule, {
      propsData: {
        ...props,
      },
      ...options,
    });
  };

  describe.each`
    rule                 | ruleName                  | descriptionText
    ${coverageCheckRule} | ${coverageCheckRule.name} | ${coverageCheckRule.description}
  `('with $ruleName', ({ rule, descriptionText }) => {
    beforeEach(() => {
      createWrapper({
        rule: { ...rule },
      });
      description = findDescription();
    });

    it('should render the row with the enable decription and enable button', () => {
      expect(description.exists()).toBe(true);
      expect(description.text()).toBe(descriptionText);
      expect(findButton().exists()).toBe(true);
    });

    it('should emit the "enable" event when the button is clicked', () => {
      findButton().trigger('click');
      expect(wrapper.emitted('enable')).toEqual([[]]);
    });
  });
});
