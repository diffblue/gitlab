import { GlFormCheckbox } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import DastSiteAuthSection from 'ee/security_configuration/dast_profiles/dast_site_profiles/components/dast_site_auth_section.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

describe('DastSiteAuthSection', () => {
  let wrapper;

  const createComponent = ({
    mountFn = mount,
    fields = {},
    disabled = false,
    isTargetApi = false,
  } = {}) => {
    wrapper = extendedWrapper(
      mountFn(DastSiteAuthSection, {
        propsData: {
          disabled,
          value: { fields },
          isTargetApi,
        },
      }),
    );
  };

  beforeEach(() => {
    createComponent();
  });

  const inputFieldsWithValues = {
    url: 'http://www.gitlab.com',
    username: 'foo',
    password: 'foo',
    usernameField: 'foo',
    passwordField: 'foo',
    submitField: 'submit',
  };

  const findParentFormGroup = () => wrapper.findByTestId('dast-site-auth-parent-group');
  const findByNameAttribute = (name) => wrapper.find(`[name="${name}"]`);
  const findAuthForm = () => wrapper.findByTestId('auth-form');
  const findAuthCheckbox = () => wrapper.findComponent(GlFormCheckbox);

  const setAuthentication = async ({ enabled }) => {
    findAuthCheckbox().vm.$emit('input', enabled);
    await nextTick();
  };
  const getLatestInputEventPayload = () => {
    const latestInputEvent = [...wrapper.emitted('input')].pop();
    const [payload] = latestInputEvent;
    return payload;
  };

  describe('authentication toggle', () => {
    it('is set false by default', () => {
      createComponent();
      expect(findAuthCheckbox().vm.$attrs.checked).toBe(false);
    });

    it.each([true, false])(
      'is set correctly when the "enabled" field is set to "%s"',
      (authEnabled) => {
        createComponent({ fields: { enabled: authEnabled } });
        expect(findAuthCheckbox().vm.$attrs.checked).toBe(authEnabled);
      },
    );

    it('controls the visibility of the authentication-fields form', async () => {
      expect(findAuthForm().exists()).toBe(false);
      await setAuthentication({ enabled: true });
      expect(findAuthForm().exists()).toBe(true);
    });

    it.each([true, false])(
      'makes the component emit an "input" event when changed',
      async (enabled) => {
        await setAuthentication({ enabled });
        expect(getLatestInputEventPayload().fields.enabled).toBe(enabled);
      },
    );
  });

  describe('authentication form', () => {
    beforeEach(async () => {
      await setAuthentication({ enabled: true });
    });

    const inputFieldNames = Object.keys(inputFieldsWithValues);

    describe.each(inputFieldNames)('input field "%s"', (inputFieldName) => {
      it('is rendered', () => {
        expect(findByNameAttribute(inputFieldName).exists()).toBe(true);
      });

      it('makes the component emit an "input" event when its value changes', async () => {
        const input = findByNameAttribute(inputFieldName);
        const newValue = 'foo';

        await input.setValue(newValue);

        expect(getLatestInputEventPayload().fields[inputFieldName]).toBe(newValue);
      });
    });

    it('all inputs have correct required attribute set', () => {
      const { submitField, ...requiredFields } = inputFieldsWithValues;

      Object.keys(requiredFields).forEach((key) => {
        const input = findByNameAttribute(key);
        expect(input.attributes('required')).toBe('required');
      });

      const optionalInput = findByNameAttribute('submitField');
      expect(optionalInput.attributes('required')).toBe(undefined);
    });

    describe('validity', () => {
      it('is not valid per default', () => {
        expect(getLatestInputEventPayload().state).toBe(false);
      });

      it('is valid when correct values are passed in via the "fields" prop', async () => {
        createComponent({ fields: inputFieldsWithValues });

        await setAuthentication({ enabled: true });

        expect(getLatestInputEventPayload().state).toBe(true);
      });

      it('is valid once all fields have been entered correctly', async () => {
        Object.entries(inputFieldsWithValues).forEach(([inputFieldName, inputFieldValue]) => {
          const input = findByNameAttribute(inputFieldName);
          input.setValue(inputFieldValue);
          input.trigger('blur');
        });
        await nextTick();
        expect(getLatestInputEventPayload().state).toBe(true);
      });
    });

    describe('when profile does not come from a policy', () => {
      it('should enable all form groups', () => {
        createComponent({ mountFn: shallowMount, fields: { enabled: true } });
        expect(findParentFormGroup().attributes('disabled')).toBe(undefined);
      });
    });

    describe('when profile does comes from a policy', () => {
      it('should disable all form groups', () => {
        createComponent({ mountFn: shallowMount, disabled: true, fields: { enabled: true } });
        expect(findParentFormGroup().attributes('disabled')).toBeDefined();
      });
    });
  });

  describe('API Authentication', () => {
    const { username, password, ...nonAPIInputFieldsWithValues } = inputFieldsWithValues;
    const APIInputFieldsWithValues = { username, password };

    beforeEach(async () => {
      createComponent({
        fields: { ...APIInputFieldsWithValues },
        isTargetApi: true,
      });
      await setAuthentication({ enabled: true });
    });

    const APIInputFieldNames = Object.keys(APIInputFieldsWithValues);
    const nonAPIInputFieldNames = Object.keys(nonAPIInputFieldsWithValues);

    describe.each(APIInputFieldNames)('input field "%s"', (inputFieldName) => {
      it('is rendered', () => {
        expect(findByNameAttribute(inputFieldName).exists()).toBe(true);
      });

      it('makes the component emit an "input" event when its value changes', async () => {
        const input = findByNameAttribute(inputFieldName);
        const newValue = 'bar';
        await input.setValue(newValue);
        expect(getLatestInputEventPayload().fields[inputFieldName]).toBe(newValue);
      });
    });

    it.each(nonAPIInputFieldNames)('input field "%s" is not rendered', (inputFieldName) => {
      expect(findByNameAttribute(inputFieldName).exists()).toBe(false);
    });

    describe('validity', () => {
      it('is not valid per default', async () => {
        createComponent({
          isTargetApi: true,
        });
        await setAuthentication({ enabled: true });

        expect(getLatestInputEventPayload().state).toBe(false);
      });

      it('is valid when correct values are passed in via the "fields" prop', async () => {
        createComponent({ fields: APIInputFieldsWithValues, isTargetApi: true });

        await setAuthentication({ enabled: true });

        expect(getLatestInputEventPayload().state).toBe(true);
      });

      it('is valid once all fields have been entered correctly', async () => {
        Object.entries(APIInputFieldsWithValues).forEach(([inputFieldName, inputFieldValue]) => {
          const input = findByNameAttribute(inputFieldName);
          input.setValue(inputFieldValue);
          input.trigger('blur');
        });
        await nextTick();
        expect(getLatestInputEventPayload().state).toBe(true);
      });
    });
  });
});
