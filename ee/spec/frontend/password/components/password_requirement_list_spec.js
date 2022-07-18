import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import PasswordRequirementList from 'ee/password/components/password_requirement_list.vue';

describe('Password requirement list component', () => {
  let wrapper;
  const hiddenElementClassName = 'gl-visibility-hidden';
  const findStatusIcons = (ruleType) => wrapper.findByTestId(`password-${ruleType}-status-icon`);
  const findRedRuleTexts = () =>
    wrapper.findAllByTestId('password-rule-text').filter((c) => c.classes('gl-text-red-500'));

  beforeEach(() => {
    wrapper = extendedWrapper(
      shallowMount(PasswordRequirementList, {
        propsData: {
          submitted: false,
          password: '',
          ruleTypes: ['number', 'lowercase', 'uppercase', 'symbol'],
        },
      }),
    );
  });

  afterEach(() => {
    wrapper.destroy();
  });
  it.each`
    password  | matchNumber | matchLowerCase | matchUpperCase | matchSymbol
    ${'1'}    | ${true}     | ${false}       | ${false}       | ${false}
    ${'a'}    | ${false}    | ${true}        | ${false}       | ${false}
    ${'A'}    | ${false}    | ${false}       | ${true}        | ${false}
    ${'!'}    | ${false}    | ${false}       | ${false}       | ${true}
    ${'1a'}   | ${true}     | ${true}        | ${false}       | ${false}
    ${'٤āÁ.'} | ${true}     | ${true}        | ${true}        | ${true}
  `(
    'password $password match number $matchNumber match lowercase $matchLowerCase match uppercase $matchUpperCase match symbol $matchSymbol',
    async ({ password, matchNumber, matchLowerCase, matchUpperCase, matchSymbol }) => {
      await wrapper.setProps({ password });

      await nextTick();

      expect(findStatusIcons('number').classes(hiddenElementClassName)).toBe(!matchNumber);
      expect(findStatusIcons('lowercase').classes(hiddenElementClassName)).toBe(!matchLowerCase);
      expect(findStatusIcons('uppercase').classes(hiddenElementClassName)).toBe(!matchUpperCase);
      expect(findStatusIcons('symbol').classes(hiddenElementClassName)).toBe(!matchSymbol);

      await wrapper.setProps({ submitted: true });

      await nextTick();

      const unMatchedNumber = [matchNumber, matchLowerCase, matchUpperCase, matchSymbol].filter(
        (isMatched) => isMatched === false,
      ).length;
      expect(findRedRuleTexts().length).toBe(unMatchedNumber);
    },
  );
});
