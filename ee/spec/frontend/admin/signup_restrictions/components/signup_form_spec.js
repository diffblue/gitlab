import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import SignupForm from '~/pages/admin/application_settings/general/components/signup_form.vue';
import { mockData } from 'jest/admin/signup_restrictions/mock_data';

describe('Signup Form', () => {
  let wrapper;

  const mountComponent = ({ injectedProps = {}, mountFn = shallowMount, stubs = {} } = {}) => {
    wrapper = extendedWrapper(
      mountFn(SignupForm, {
        provide: {
          glFeatures: {
            passwordComplexity: true,
          },
          ...mockData,
          ...injectedProps,
        },
        stubs,
      }),
    );
  };

  describe('form data', () => {
    beforeEach(() => {
      mountComponent();
    });

    it.each`
      prop                           | propValue                             | elementSelector                                                | formElementPassedDataType | formElementKey | expected
      ${'passwordNumberRequired'}    | ${mockData.passwordNumberRequired}    | ${'[name="application_setting[password_number_required]"]'}    | ${'prop'}                 | ${'value'}     | ${mockData.passwordNumberRequired}
      ${'passwordLowercaseRequired'} | ${mockData.passwordLowercaseRequired} | ${'[name="application_setting[password_lowercase_required]"]'} | ${'prop'}                 | ${'value'}     | ${mockData.passwordLowercaseRequired}
      ${'passwordUppercaseRequired'} | ${mockData.passwordUppercaseRequired} | ${'[name="application_setting[password_uppercase_required]"]'} | ${'prop'}                 | ${'value'}     | ${mockData.passwordUppercaseRequired}
      ${'passwordSymbolRequired'}    | ${mockData.passwordSymbolRequired}    | ${'[name="application_setting[password_symbol_required]"]'}    | ${'prop'}                 | ${'value'}     | ${mockData.passwordSymbolRequired}
    `(
      'form element $elementSelector gets $expected value for $formElementKey $formElementPassedDataType when prop $prop is set to $propValue',
      ({ elementSelector, expected, formElementKey, formElementPassedDataType }) => {
        const formElement = wrapper.find(elementSelector);

        switch (formElementPassedDataType) {
          case 'attribute':
            expect(formElement.attributes(formElementKey)).toBe(expected);
            break;
          case 'prop':
            expect(formElement.props(formElementKey)).toBe(expected);
            break;
          case 'value':
            expect(formElement.element.value).toBe(expected);
            break;
          default:
            expect(formElement.props(formElementKey)).toBe(expected);
            break;
        }
      },
    );
  });
});
