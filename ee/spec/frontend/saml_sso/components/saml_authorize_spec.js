import { GlFormCheckbox, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import { I18N, REMEMBER_ME_PARAM } from 'ee/saml_sso/constants';
import SamlAuthorize from 'ee/saml_sso/components/saml_authorize.vue';

describe('SamlAuthorize', () => {
  let wrapper;

  const groupName = 'My group';
  const groupUrl = '/mygroup';
  const rememberable = true;
  const samlUrl = '/saml_url';
  const username = 'jack';
  const userFullName = 'Jack Smith';
  const userUrl = '/jack';

  const createComponent = (provide = {}) => {
    wrapper = shallowMount(SamlAuthorize, {
      provide: {
        groupName,
        groupUrl,
        rememberable,
        samlUrl,
        username,
        userFullName,
        userUrl,
        ...provide,
      },
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);
  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);

  it('has an `Authorized` button', () => {
    createComponent();

    const button = findButton();
    expect(button.text()).toBe(I18N.authorizeButton);
    expect(button.attributes('data-method')).toBe('post');
  });

  describe('when rememberable is false', () => {
    it('hides the `Remember me` checkbox', () => {
      createComponent({ rememberable: false });

      expect(findCheckbox().exists()).toBe(false);
    });
  });

  describe('when rememberable is true', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows the `Remember me` checkbox', () => {
      expect(findCheckbox().exists()).toBe(true);
    });

    describe('when checkbox is toggled', () => {
      it(`adds the '${REMEMBER_ME_PARAM}' query parameter to the SAML URL`, async () => {
        expect(findButton().attributes('href')).not.toContain(REMEMBER_ME_PARAM);

        await findCheckbox().vm.$emit('change', true);

        expect(findButton().attributes('href')).toContain(`${REMEMBER_ME_PARAM}=1`);
      });

      it(`removes the '${REMEMBER_ME_PARAM}' query parameter from the SAML URL`, async () => {
        await findCheckbox().vm.$emit('change', true);
        expect(findButton().attributes('href')).toContain(`${REMEMBER_ME_PARAM}=1`);

        await findCheckbox().vm.$emit('change', false);

        expect(findButton().attributes('href')).not.toContain('REMEMBER_ME_PARAM');
      });
    });
  });
});
