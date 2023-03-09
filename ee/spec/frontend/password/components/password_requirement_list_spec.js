import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import {
  RED_TEXT_CLASS,
  GREEN_TEXT_CLASS,
  HIDDEN_ELEMENT_CLASS,
  INVALID_INPUT_CLASS,
  INVALID_FORM_CLASS,
  I18N,
} from 'ee/password/constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import PasswordRequirementList from 'ee/password/components/password_requirement_list.vue';

describe('Password requirement list component', () => {
  let wrapper;

  const PASSWORD_INPUT_CLASS = 'js-password-complexity-validation';
  const findStatusIcon = (ruleType) => wrapper.findByTestId(`password-${ruleType}-status-icon`);
  const findRuleTextsByClass = (colorClassName) =>
    wrapper.findAllByTestId('password-rule-text').filter((c) => c.classes(colorClassName));
  const findPasswordInputElement = () => document.querySelector(`.${PASSWORD_INPUT_CLASS}`);
  const findForm = () => findPasswordInputElement().form;
  const findSubmitButton = () => findForm().querySelector('[type="submit"]');
  const ruleTypes = ['number', 'lowercase', 'uppercase', 'symbol'];

  const createComponent = ({ props = {} } = {}) => {
    const passwordInputElement = findPasswordInputElement();
    wrapper = extendedWrapper(
      shallowMount(PasswordRequirementList, {
        propsData: {
          passwordInputElement,
          ruleTypes,
          ...props,
        },
      }),
    );
  };

  beforeEach(() => {
    setHTMLFixture(`
      <form>
        <input autocomplete="new-password" class="form-control gl-form-input ${PASSWORD_INPUT_CLASS}" type="password" name="user[password]" id="user_password">
        <input type="submit" name="commit" value="Submit">
      </form>
    `);
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('when empty password is not allowed', () => {
    beforeEach(() => {
      createComponent({
        props: {
          allowNoPassword: false,
        },
      });
      findPasswordInputElement().value = '';
    });
    it('should show when password is empty', () => {
      const passwordRules = wrapper.findAllByTestId('password-requirement-list');
      expect(passwordRules.isVisible()).toBe(true);
    });

    it('should not allow submit when password is empty', () => {
      findSubmitButton().dispatchEvent(new Event('click'));
      expect(findPasswordInputElement().classList.contains(INVALID_INPUT_CLASS)).toBe(true);
    });
  });

  describe('when empty password is allowed', () => {
    beforeEach(() => {
      createComponent({
        props: {
          allowNoPassword: true,
        },
      });
      findPasswordInputElement().value = '';
    });
    it('should hide when password is empty', () => {
      const passwordRules = wrapper.findAllByTestId('password-requirement-list');
      expect(passwordRules.isVisible()).toBe(false);
    });

    it('should allow submit when password is empty', () => {
      findSubmitButton().dispatchEvent(new Event('click'));
      expect(findPasswordInputElement().classList.contains(INVALID_INPUT_CLASS)).toBe(false);
    });
  });

  describe.each`
    password  | matchNumber | matchLowerCase | matchUpperCase | matchSymbol
    ${'1'}    | ${true}     | ${false}       | ${false}       | ${false}
    ${'a'}    | ${false}    | ${true}        | ${false}       | ${false}
    ${'A'}    | ${false}    | ${false}       | ${true}        | ${false}
    ${'!'}    | ${false}    | ${false}       | ${false}       | ${true}
    ${'1a'}   | ${true}     | ${true}        | ${false}       | ${false}
    ${'٤āÁ.'} | ${true}     | ${true}        | ${true}        | ${true}
  `(
    'password $password',
    ({ password, matchNumber, matchLowerCase, matchUpperCase, matchSymbol }) => {
      beforeEach(() => {
        createComponent({
          props: {
            allowNoPassword: false,
          },
        });
        const passwordInputElement = findPasswordInputElement();
        passwordInputElement.value = password;
        passwordInputElement.dispatchEvent(new Event('input'));
      });
      const resultList = [matchNumber, matchLowerCase, matchUpperCase, matchSymbol];
      const ruleAndResultTable = ruleTypes.map((ruleType, index) => [ruleType, resultList[index]]);

      describe.each(ruleAndResultTable)('match %s %s', (ruleType, result) => {
        it(`should show checked icon correctly on ${ruleType} line`, async () => {
          await nextTick();

          expect(findStatusIcon(ruleType).classes(HIDDEN_ELEMENT_CLASS)).toBe(!result);
        });

        it(`should aria label correctly on ${ruleType} line`, async () => {
          const submitButton = findSubmitButton();

          await nextTick();

          expect(findStatusIcon(ruleType).attributes('aria-label')).toBe(
            result ? I18N.PASSWORD_SATISFIED : I18N.PASSWORD_TO_BE_SATISFIED,
          );
          submitButton.dispatchEvent(new Event('click'));

          await nextTick();

          expect(findStatusIcon(ruleType).attributes('aria-label')).toBe(
            result ? I18N.PASSWORD_SATISFIED : I18N.PASSWORD_NOT_SATISFIED,
          );
        });
      });

      it('should show red text on rule and red border on input after submit', async () => {
        const passwordInputElement = findPasswordInputElement();
        const form = findForm();
        const submitButton = findSubmitButton();
        submitButton.dispatchEvent(new Event('click'));

        await nextTick();

        const unMatchedNumber = resultList.filter((isMatched) => isMatched === false).length;

        if (unMatchedNumber > 0) {
          expect(passwordInputElement.classList.contains(INVALID_INPUT_CLASS)).toBe(true);
          expect(form.classList.contains(INVALID_FORM_CLASS)).toBe(true);
        }
        expect(findRuleTextsByClass(RED_TEXT_CLASS).length).toBe(unMatchedNumber);
        expect(findRuleTextsByClass(GREEN_TEXT_CLASS).length).toBe(
          wrapper.vm.ruleTypes.length - unMatchedNumber,
        );
      });
    },
  );
});
