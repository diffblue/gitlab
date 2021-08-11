import { GlForm, GlModal } from '@gitlab/ui';
import { within } from '@testing-library/dom';
import { createLocalVue, mount } from '@vue/test-utils';
import merge from 'lodash/merge';
import { createMockClient } from 'mock-apollo-client';
import VueApollo from 'vue-apollo';
import BaseDastProfileForm from 'ee/security_configuration/dast_profiles/components/base_dast_profile_form.vue';
import DastSiteAuthSection from 'ee/security_configuration/dast_profiles/dast_site_profiles/components/dast_site_auth_section.vue';
import DastSiteProfileForm from 'ee/security_configuration/dast_profiles/dast_site_profiles/components/dast_site_profile_form.vue';
import dastSiteProfileCreateMutation from 'ee/security_configuration/dast_profiles/dast_site_profiles/graphql/dast_site_profile_create.mutation.graphql';
import dastSiteProfileUpdateMutation from 'ee/security_configuration/dast_profiles/dast_site_profiles/graphql/dast_site_profile_update.mutation.graphql';
import { siteProfiles, policySiteProfile } from 'ee_jest/on_demand_scans/mocks/mock_data';
import * as responses from 'ee_jest/security_configuration/dast_profiles/dast_site_profiles/mock_data/apollo_mock';
import { TEST_HOST } from 'helpers/test_constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

const localVue = createLocalVue();
localVue.use(VueApollo);

const [siteProfileOne] = siteProfiles;
const projectFullPath = 'group/project';
const profilesLibraryPath = `${TEST_HOST}/${projectFullPath}/-/security/configuration/dast_scans`;
const onDemandScansPath = `${TEST_HOST}/${projectFullPath}/-/on_demand_scans`;
const profileName = 'My DAST site profile';
const targetUrl = 'http://example.com';
const excludedUrls = 'https://foo.com/logout, https://foo.com/send_mail';
const requestHeaders = 'my-new-header=something';

const defaultProps = {
  profilesLibraryPath,
  onDemandScansPath,
};

const defaultRequestHandlers = {
  dastSiteProfileCreate: jest.fn().mockResolvedValue(responses.dastSiteProfileCreate()),
  dastSiteProfileUpdate: jest.fn().mockResolvedValue(responses.dastSiteProfileUpdate()),
};

describe('DastSiteProfileForm', () => {
  let wrapper;
  let apolloProvider;
  let requestHandlers;

  const withinComponent = () => within(wrapper.element);

  const findForm = () => wrapper.findComponent(GlForm);
  const findBaseDastProfileForm = () => wrapper.findComponent(BaseDastProfileForm);
  const findParentFormGroup = () => wrapper.findByTestId('dast-site-parent-group');
  const findAuthSection = () => wrapper.findComponent(DastSiteAuthSection);
  const findCancelModal = () => wrapper.findComponent(GlModal);
  const findByNameAttribute = (name) => wrapper.find(`[name="${name}"]`);
  const findProfileNameInput = () => wrapper.findByTestId('profile-name-input');
  const findTargetUrlInput = () => wrapper.findByTestId('target-url-input');
  const findExcludedUrlsInput = () => wrapper.findByTestId('excluded-urls-input');
  const findRequestHeadersInput = () => wrapper.findByTestId('request-headers-input');
  const findAuthCheckbox = () => wrapper.findByTestId('auth-enable-checkbox');
  const findTargetTypeOption = () => wrapper.findByTestId('site-type-option');
  const findSubmitButton = () => wrapper.findByTestId('dast-profile-form-submit-button');
  const findCancelButton = () => wrapper.findByTestId('dast-profile-form-cancel-button');
  const findAlert = () => wrapper.findByTestId('dast-profile-form-alert');
  const findPolicyAlert = () => wrapper.findByTestId('dast-policy-profile-alert');
  const submitForm = () => findForm().vm.$emit('submit', { preventDefault: () => {} });

  const setFieldValue = async (field, value) => {
    await field.setValue(value);
    field.trigger('blur');
  };

  const setAuthFieldsValues = async ({ enabled, ...fields }) => {
    await findAuthCheckbox().setChecked(enabled);

    Object.keys(fields).forEach((field) => {
      findByNameAttribute(field).setValue(fields[field]);
    });
  };

  const fillForm = async () => {
    await setFieldValue(findProfileNameInput(), profileName);
    await setFieldValue(findTargetUrlInput(), targetUrl);
    await setFieldValue(findExcludedUrlsInput(), excludedUrls);
    await setFieldValue(findRequestHeadersInput(), requestHeaders);
    await setAuthFieldsValues(siteProfileOne.auth);
  };

  const fillAndSubmitForm = async () => {
    await fillForm();
    submitForm();
  };

  const setTargetType = async (type) => {
    const radio = wrapper
      .findAll('input[type="radio"]')
      .filter((r) => r.attributes('value') === type)
      .at(0);
    radio.element.selected = true;
    radio.trigger('change');
  };

  const mockClientFactory = (handlers) => {
    const mockClient = createMockClient();

    requestHandlers = {
      ...defaultRequestHandlers,
      ...handlers,
    };

    mockClient.setRequestHandler(
      dastSiteProfileCreateMutation,
      requestHandlers.dastSiteProfileCreate,
    );

    mockClient.setRequestHandler(
      dastSiteProfileUpdateMutation,
      requestHandlers.dastSiteProfileUpdate,
    );

    return mockClient;
  };

  const respondWith = (handlers) => {
    apolloProvider.defaultClient = mockClientFactory(handlers);
  };

  const createComponent = (options, handlers) => {
    apolloProvider = new VueApollo({
      defaultClient: mockClientFactory(handlers),
    });

    const mountOpts = merge(
      {},
      {
        propsData: defaultProps,
        provide: { projectFullPath },
      },
      options,
      {
        localVue,
        apolloProvider,
      },
    );

    wrapper = extendedWrapper(mount(DastSiteProfileForm, mountOpts));
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    apolloProvider = null;
  });

  it('renders properly', () => {
    createComponent();
    expect(findForm().exists()).toBe(true);
    expect(findForm().text()).toContain('New site profile');
  });

  it('when showHeader prop is disabled', () => {
    createComponent({
      propsData: {
        ...defaultProps,
        showHeader: false,
      },
    });
    expect(findForm().text()).not.toContain('New site profile');
  });

  describe('target URL input', () => {
    const errorMessage = 'Please enter a valid URL format, ex: http://www.example.com/home';

    beforeEach(() => {
      createComponent();
    });

    it.each(['asd', 'example.com'])(
      'is marked as invalid provided an invalid URL',
      async (value) => {
        await setFieldValue(findTargetUrlInput(), value);

        expect(wrapper.text()).toContain(errorMessage);
      },
    );

    it('is marked as valid provided a valid URL', async () => {
      await setFieldValue(findTargetUrlInput(), targetUrl);

      expect(wrapper.text()).not.toContain(errorMessage);
    });
  });

  describe('additional fields', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should render correctly with default values', () => {
      expect(findAuthSection().exists()).toBe(true);
      expect(findExcludedUrlsInput().exists()).toBe(true);
      expect(findRequestHeadersInput().exists()).toBe(true);
      expect(findTargetTypeOption().vm.$attrs.checked).toBe('WEBSITE');
    });

    it('should have maxlength constraint', () => {
      expect(findExcludedUrlsInput().attributes('maxlength')).toBe('2048');
      expect(findRequestHeadersInput().attributes('maxlength')).toBe('2048');
    });

    describe('request-headers and password fields renders correctly', () => {
      it('when creating a new profile', async () => {
        expect(findRequestHeadersInput().attributes('placeholder')).toBe(
          'Cache-control: no-cache, User-Agent: DAST/1.0',
        );

        expect(findRequestHeadersInput().element.value).toBe('');
        expect(findByNameAttribute('password').exists()).toBe(false);
      });

      it('when updating an existing profile', () => {
        createComponent({
          propsData: {
            profile: siteProfileOne,
          },
        });
        expect(findRequestHeadersInput().element.value).toBe(siteProfileOne.requestHeaders);
        expect(findByNameAttribute('password').element.value).toBe(siteProfileOne.auth.password);
      });

      it('when updating an existing profile with no request-header & password', () => {
        createComponent({
          propsData: {
            profile: { ...siteProfileOne, requestHeaders: null, auth: { enabled: true } },
          },
        });
        expect(findRequestHeadersInput().element.value).toBe('');
        expect(findByNameAttribute('password').element.value).toBe('');
      });
    });

    describe('when target type is API', () => {
      beforeEach(() => {
        setTargetType('API');
      });

      it('should hide auth section', () => {
        expect(findAuthSection().exists()).toBe(false);
      });

      describe.each`
        title                  | profile           | mutationVars                 | mutationKind
        ${'New site profile'}  | ${{}}             | ${{}}                        | ${'dastSiteProfileCreate'}
        ${'Edit site profile'} | ${siteProfileOne} | ${{ id: siteProfileOne.id }} | ${'dastSiteProfileUpdate'}
      `('$title', ({ profile, mutationVars, mutationKind }) => {
        beforeEach(() => {
          createComponent({
            propsData: {
              profile,
            },
          });
        });

        it('form submission triggers correct GraphQL mutation', async () => {
          await fillForm();
          await setTargetType('API');
          await submitForm();

          expect(requestHandlers[mutationKind]).toHaveBeenCalledWith({
            input: {
              profileName,
              targetUrl,
              fullPath: projectFullPath,
              excludedUrls: siteProfileOne.excludedUrls,
              requestHeaders,
              targetType: 'API',
              ...mutationVars,
            },
          });
        });
      });
    });
  });

  describe.each`
    title                  | profile           | mutationVars                 | mutationKind
    ${'New site profile'}  | ${{}}             | ${{}}                        | ${'dastSiteProfileCreate'}
    ${'Edit site profile'} | ${siteProfileOne} | ${{ id: siteProfileOne.id }} | ${'dastSiteProfileUpdate'}
  `('$title', ({ profile, title, mutationVars, mutationKind }) => {
    beforeEach(() => {
      createComponent({
        propsData: {
          profile,
        },
      });
    });

    it('sets the correct title', () => {
      expect(withinComponent().getByRole('heading', { name: title })).not.toBeNull();
    });

    it('populates the fields with the data passed in via the siteProfile prop', () => {
      expect(findProfileNameInput().element.value).toBe(profile?.name ?? '');
    });

    describe('submission', () => {
      describe('on success', () => {
        beforeEach(async () => {
          await fillAndSubmitForm();
        });

        it('sets loading state', () => {
          expect(findSubmitButton().props('loading')).toBe(true);
        });

        it('triggers GraphQL mutation', () => {
          expect(requestHandlers[mutationKind]).toHaveBeenCalledWith({
            input: {
              profileName,
              targetUrl,
              requestHeaders,
              fullPath: projectFullPath,
              auth: siteProfileOne.auth,
              excludedUrls: siteProfileOne.excludedUrls,
              targetType: siteProfileOne.targetType,
              ...mutationVars,
            },
          });
        });

        it('emits success event with correct params', () => {
          const baseDastProfileForm = findBaseDastProfileForm();
          expect(baseDastProfileForm.emitted('success')).toBeTruthy();
          expect(baseDastProfileForm.emitted('success')).toHaveLength(1);
          expect(baseDastProfileForm.emitted('success')[0]).toStrictEqual([{ id: '3083' }]);
        });

        it('does not show an alert', () => {
          expect(findAlert().exists()).toBe(false);
        });
      });

      describe('on top-level error', () => {
        beforeEach(async () => {
          respondWith({
            [mutationKind]: jest.fn().mockRejectedValue(new Error('GraphQL Network Error')),
          });

          await fillAndSubmitForm();
          await waitForPromises();
        });

        it('resets loading state', () => {
          expect(findSubmitButton().props('loading')).toBe(false);
        });

        it('shows an error alert', async () => {
          await wrapper.vm.$nextTick();

          expect(findAlert().exists()).toBe(true);
        });
      });

      describe('on errors as data', () => {
        const errors = ['error#1', 'error#2', 'error#3'];

        beforeEach(async () => {
          respondWith({
            [mutationKind]: jest.fn().mockResolvedValue(responses[mutationKind](errors)),
          });

          await fillAndSubmitForm();
          await waitForPromises();
        });

        it('resets loading state', () => {
          expect(findSubmitButton().props('loading')).toBe(false);
        });

        it('shows an alert with the returned errors', () => {
          const alert = findAlert();

          expect(alert.exists()).toBe(true);
          errors.forEach((error) => {
            expect(alert.text()).toContain(error);
          });
        });
      });
    });

    describe('cancellation', () => {
      describe('form unchanged', () => {
        it('emits cancel event', () => {
          findCancelButton().vm.$emit('click');
          expect(findBaseDastProfileForm().emitted('cancel')).toBeTruthy();
        });
      });

      describe('form changed', () => {
        beforeEach(() => {
          findTargetUrlInput().setValue(targetUrl);
          findProfileNameInput().setValue(profileName);
        });

        it('asks the user to confirm the action', () => {
          jest.spyOn(findCancelModal().vm, 'show').mockReturnValue();
          findCancelButton().trigger('click');
          expect(findCancelModal().vm.show).toHaveBeenCalled();
        });

        it('emits cancel event', () => {
          findCancelModal().vm.$emit('ok');
          expect(findBaseDastProfileForm().emitted('cancel')).toBeTruthy();
        });
      });
    });
  });

  describe('when profile does not come from a policy', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          profile: siteProfileOne,
        },
      });
    });

    it('should enable all form groups', () => {
      expect(findParentFormGroup().attributes('disabled')).toBe(undefined);
    });

    it('should show the policy profile alert', () => {
      expect(findPolicyAlert().exists()).toBe(false);
    });
  });

  describe('when profile does comes from a policy', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          profile: policySiteProfile,
        },
      });
    });

    it('should show the policy profile alert', () => {
      expect(findPolicyAlert().exists()).toBe(true);
    });

    it('should disable all form groups', () => {
      expect(findParentFormGroup().attributes('disabled')).toBe('disabled');
    });

    it('should disable the save button', () => {
      expect(findSubmitButton().props('disabled')).toBe(true);
    });
  });
});
