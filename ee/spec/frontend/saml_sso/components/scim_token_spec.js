import { merge, pickBy, isUndefined } from 'lodash';
import AxiosMockAdapter from 'axios-mock-adapter';
import { GlLoadingIcon, GlModal } from '@gitlab/ui';

import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { createAlert } from '~/alert';
import ScimToken from 'ee/saml_sso/components/scim_token.vue';
import InputCopyToggleVisibility from '~/vue_shared/components/form/input_copy_toggle_visibility.vue';

jest.mock('~/alert');

describe('ScimToken', () => {
  let wrapper;
  let axiosMock;

  const defaultProvide = {
    initialEndpointUrl: undefined,
    generateTokenPath: '/groups/saml-test/-/scim_oauth',
  };

  const mockApiResponse = {
    scim_api_url: 'https://foo.bar/api/scim/v2/groups/saml-test',
    scim_token: 'quL51_RR49CcHpjxJN_S',
  };

  const createComponent = (options = {}) => {
    wrapper = mountExtended(
      ScimToken,
      merge(
        {},
        {
          provide: defaultProvide,
        },
        options,
      ),
    );
  };

  const findGenerateTokenButton = () =>
    wrapper.findByRole('button', { name: ScimToken.i18n.generateTokenButtonText });
  const findResetItButton = () => wrapper.findByRole('button', { name: 'reset it' });
  const resetAndConfirm = async () => {
    await findResetItButton().trigger('click');
    wrapper.findComponent(GlModal).vm.$emit('primary');
  };

  const expectLoadingIconExists = () => {
    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    expect(wrapper.findByTestId('content-container').classes()).toContain('gl-visibility-hidden');
  };
  const expectInputRenderedWithProps = (input, props) => {
    const {
      formInputGroupProps,
      value,
      copyButtonTitle,
      showToggleVisibilityButton,
      showCopyButton,
      label,
      labelFor,
    } = props;

    expect(input.props()).toMatchObject(
      pickBy(
        {
          formInputGroupProps,
          value,
          copyButtonTitle,
          showToggleVisibilityButton,
          showCopyButton,
        },
        !isUndefined,
      ),
    );

    expect(input.attributes()).toMatchObject({
      label,
      'label-for': labelFor,
    });
  };

  const itShowsLoadingIconThenDisplaysInputs = () => {
    it('shows loading icon then displays token in hidden state and SCIM API endpoint URL', async () => {
      // FIXME(vitallium): Resolve after migrating to Jest modern fake timers implementation
      // expectLoadingIconExists();

      await waitForPromises();

      const [tokenInput, apiEndpointInput] = wrapper.findAllComponents(
        InputCopyToggleVisibility,
      ).wrappers;

      expectInputRenderedWithProps(tokenInput, {
        formInputGroupProps: { id: ScimToken.tokenInputId, class: 'gl-form-input-xl' },
        value: mockApiResponse.scim_token,
        copyButtonTitle: ScimToken.i18n.copyToken,
        showToggleVisibilityButton: true,
        showCopyButton: true,
        label: ScimToken.i18n.tokenLabel,
        labelFor: ScimToken.tokenInputId,
      });

      expect(
        wrapper.findByText(ScimToken.i18n.tokenHasBeenGeneratedOrResetDescription).exists(),
      ).toBe(true);

      expectInputRenderedWithProps(apiEndpointInput, {
        formInputGroupProps: { id: ScimToken.endpointUrlInputId, class: 'gl-form-input-xl' },
        value: mockApiResponse.scim_api_url,
        copyButtonTitle: ScimToken.i18n.copyEndpointUrl,
        showToggleVisibilityButton: false,
        label: ScimToken.i18n.endpointUrlLabel,
        labelFor: ScimToken.endpointUrlInputId,
      });
    });
  };
  const itShowsLoadingIconThenCallsCreateAlert = (expectedErrorMessage) => {
    it('shows loading icon then calls `createAlert`', async () => {
      expectLoadingIconExists();

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: expectedErrorMessage,
        captureError: true,
        error: expect.any(Error),
      });
    });
  };

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('when token has not been generated', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays message and button to generate token', () => {
      expect(wrapper.findByText(ScimToken.i18n.tokenHasNotBeenGeneratedMessage).exists()).toBe(
        true,
      );
      expect(findGenerateTokenButton().exists()).toBe(true);
    });

    describe(`when \`${ScimToken.i18n.generateTokenButtonText}\` button is clicked`, () => {
      describe('when API request is successful', () => {
        beforeEach(async () => {
          axiosMock.onPost(defaultProvide.generateTokenPath).reply(HTTP_STATUS_OK, mockApiResponse);

          await findGenerateTokenButton().trigger('click');
        });

        itShowsLoadingIconThenDisplaysInputs();
      });

      describe('when API request is not successful', () => {
        beforeEach(async () => {
          axiosMock.onPost(defaultProvide.generateTokenPath).networkError();

          await findGenerateTokenButton().trigger('click');
        });

        itShowsLoadingIconThenCallsCreateAlert(ScimToken.i18n.generateTokenErrorMessage);
      });
    });
  });

  describe('when token has been generated but needs to be reset', () => {
    const initialEndpointUrl = 'https://foo.bar/api/scim/v2/groups/saml-test';

    beforeEach(() => {
      createComponent({
        provide: {
          initialEndpointUrl,
        },
      });
    });

    it('displays message and reset link', () => {
      expect(
        wrapper
          .findByText(
            'The SCIM token is now hidden. To see the value of the token again, you need to',
            { exact: false },
          )
          .exists(),
      ).toBe(true);

      expect(wrapper.findByRole('button', { name: 'reset it' }).exists()).toBe(true);
    });

    it('displays hidden token and SCIM API endpoint URL', () => {
      const [tokenInput, apiEndpointInput] = wrapper.findAllComponents(
        InputCopyToggleVisibility,
      ).wrappers;

      expectInputRenderedWithProps(tokenInput, {
        formInputGroupProps: { id: ScimToken.tokenInputId, class: 'gl-form-input-xl' },
        value: '********************',
        showToggleVisibilityButton: false,
        showCopyButton: false,
        label: ScimToken.i18n.tokenLabel,
        labelFor: ScimToken.tokenInputId,
      });

      expectInputRenderedWithProps(apiEndpointInput, {
        formInputGroupProps: { id: ScimToken.endpointUrlInputId, class: 'gl-form-input-xl' },
        value: initialEndpointUrl,
        copyButtonTitle: ScimToken.i18n.copyEndpointUrl,
        showToggleVisibilityButton: false,
        label: ScimToken.i18n.endpointUrlLabel,
        labelFor: ScimToken.endpointUrlInputId,
      });
    });

    describe('when `reset it` button is clicked', () => {
      describe('when API request is successful', () => {
        beforeEach(() => {
          axiosMock.onPost(defaultProvide.generateTokenPath).reply(HTTP_STATUS_OK, mockApiResponse);

          resetAndConfirm();
        });

        itShowsLoadingIconThenDisplaysInputs();
      });

      describe('when API request is not successful', () => {
        beforeEach(() => {
          axiosMock.onPost(defaultProvide.initialEndpointUrl).networkError();

          resetAndConfirm();
        });

        itShowsLoadingIconThenCallsCreateAlert(ScimToken.i18n.resetTokenErrorMessage);
      });
    });
  });
});
