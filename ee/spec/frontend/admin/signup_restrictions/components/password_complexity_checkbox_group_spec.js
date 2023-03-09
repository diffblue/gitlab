import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import PasswordComplexityCheckboxGroup from 'ee/pages/admin/application_settings/general/components/password_complexity_checkbox_group.vue';
import SignupCheckbox from '~/pages/admin/application_settings/general/components/signup_checkbox.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { mockData } from 'jest/admin/signup_restrictions/mock_data';

describe('Password Checkbox Group', () => {
  let wrapper;
  const {
    passwordNumberRequired,
    passwordLowercaseRequired,
    passwordUppercaseRequired,
    passwordSymbolRequired,
  } = mockData;

  const mountComponent = () => {
    wrapper = extendedWrapper(
      shallowMount(PasswordComplexityCheckboxGroup, {
        provide: mockData,
        stubs: {
          SignupCheckbox,
        },
      }),
    );
  };

  describe('Signup Checkbox', () => {
    beforeEach(() => {
      mountComponent();
    });
    it.each`
      prop                           | propValue                    | expected                     | testId
      ${'passwordNumberRequired'}    | ${passwordNumberRequired}    | ${passwordNumberRequired}    | ${'password-number-required-checkbox'}
      ${'passwordLowercaseRequired'} | ${passwordLowercaseRequired} | ${passwordLowercaseRequired} | ${'password-lowercase-required-checkbox'}
      ${'passwordUppercaseRequired'} | ${passwordUppercaseRequired} | ${passwordUppercaseRequired} | ${'password-uppercase-required-checkbox'}
      ${'passwordSymbolRequired'}    | ${passwordSymbolRequired}    | ${passwordSymbolRequired}    | ${'password-symbol-required-checkbox'}
    `(
      'component form data should be $expected when prop $prop is set to $propValue',
      async ({ prop, expected, testId }) => {
        const checkbox = wrapper.findByTestId(testId);
        expect(checkbox.props('value')).toBe(expected);
        checkbox.vm.$emit('input', !expected);
        await nextTick();

        expect(checkbox.props('value')).toBe(!expected);
        expect(wrapper.emitted('set-password-complexity')).toHaveLength(1);
        expect(wrapper.emitted('set-password-complexity')[0]).toEqual([
          { name: prop, value: !expected },
        ]);
      },
    );
  });
});
