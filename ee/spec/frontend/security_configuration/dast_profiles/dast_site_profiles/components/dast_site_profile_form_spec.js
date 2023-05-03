import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlForm } from '@gitlab/ui';
import { within } from '@testing-library/dom';
import merge from 'lodash/merge';
import siteProfileWithSecrets from 'test_fixtures/security_configuration/dast_profiles/dast_site_profile_with_secrets.json';
import BaseDastProfileForm from 'ee/security_configuration/dast_profiles/components/base_dast_profile_form.vue';
import DastSiteAuthSection from 'ee/security_configuration/dast_profiles/dast_site_profiles/components/dast_site_auth_section.vue';
import DastSiteProfileForm from 'ee/security_configuration/dast_profiles/dast_site_profiles/components/dast_site_profile_form.vue';
import dastSiteProfileCreateMutation from 'ee/security_configuration/dast_profiles/dast_site_profiles/graphql/dast_site_profile_create.mutation.graphql';
import dastSiteProfileUpdateMutation from 'ee/security_configuration/dast_profiles/dast_site_profiles/graphql/dast_site_profile_update.mutation.graphql';
import { policySiteProfiles } from 'ee_jest/security_configuration/dast_profiles/mocks/mock_data';
import resolvers from 'ee/vue_shared/security_configuration/graphql/resolvers/resolvers';
import { typePolicies } from 'ee/vue_shared/security_configuration/graphql/provider';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  SCAN_METHODS,
  TARGET_TYPES,
} from 'ee/security_configuration/dast_profiles/dast_site_profiles/constants';

const projectFullPath = 'group/project';
const profilesLibraryPath = `${TEST_HOST}/${projectFullPath}/-/security/configuration/profile_library`;
const onDemandScansPath = `${TEST_HOST}/${projectFullPath}/-/on_demand_scans`;
const profileName = 'My DAST site profile';
const targetUrl = 'http://example.com';
const excludedUrls = 'https://foo.com/logout, https://foo.com/send_mail';
const requestHeaders = 'my-new-header=something';
const scanFilePath = 'test-path';

const defaultProps = {
  profilesLibraryPath,
  onDemandScansPath,
  projectFullPath,
};

Vue.use(VueApollo);

describe('DastSiteProfileForm', () => {
  let wrapper;

  const withinComponent = () => within(wrapper.element);

  const findForm = () => wrapper.findComponent(GlForm);
  const findBaseDastProfileForm = () => wrapper.findComponent(BaseDastProfileForm);
  const findParentFormGroup = () => wrapper.findByTestId('dast-site-parent-group');
  const findAuthSection = () => wrapper.findComponent(DastSiteAuthSection);
  const findByNameAttribute = (name) => wrapper.find(`[name="${name}"]`);
  const findProfileNameInput = () => wrapper.findByTestId('profile-name-input');
  const findTargetUrlInput = () => wrapper.findByTestId('target-url-input');
  const findExcludedUrlsInput = () => wrapper.findByTestId('excluded-urls-input');
  const findRequestHeadersInput = () => wrapper.findByTestId('request-headers-input');
  const findScanMethodInput = () => wrapper.findByTestId('scan-method-select-input');
  const scanFilePathInput = () => wrapper.findByTestId('scan-file-path-input');
  const findAuthCheckbox = () => wrapper.findByTestId('auth-enable-checkbox');
  const findTargetTypeOption = () => wrapper.findByTestId('site-type-option');
  const findGraphQlHelpText = () => wrapper.findByTestId('graphql-help-text');

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
    await setAuthFieldsValues(siteProfileWithSecrets.auth);
  };

  const setTargetType = (type) => {
    const radio = wrapper
      .findAll('input[type="radio"]')
      .filter((r) => r.attributes('value') === type)
      .at(0);
    radio.element.selected = true;
    return radio.trigger('change');
  };

  const createComponentFactory = (mountFn = mountExtended) => (options = {}) => {
    const apolloProvider = createMockApollo([], resolvers, { typePolicies });

    const mountOpts = merge(
      {},
      {
        propsData: defaultProps,
      },
      {
        apolloProvider,
      },
      options,
    );

    wrapper = mountFn(DastSiteProfileForm, mountOpts);
  };
  const createShallowComponent = createComponentFactory(shallowMountExtended);
  const createComponent = createComponentFactory();

  it('renders properly', () => {
    createComponent();
    expect(findForm().exists()).toBe(true);
    expect(findForm().text()).toContain('New site profile');
    expect(findProfileNameInput().attributes('disabled')).toBeUndefined();
  });

  it('when show header is disabled', () => {
    createShallowComponent({
      propsData: {
        ...defaultProps,
        showHeader: false,
        stacked: true,
      },
    });
    expect(findBaseDastProfileForm().props('showHeader')).toBe(false);
  });

  describe('target URL input', () => {
    const errorMessage = 'Please enter a valid URL format, ex: http://www.example.com/home';

    beforeEach(async () => {
      createComponent();
      await waitForPromises();
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
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
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
      it('when creating a new profile', () => {
        expect(findRequestHeadersInput().attributes('placeholder')).toBe(
          'Cache-control: no-cache, User-Agent: DAST/1.0',
        );

        expect(findRequestHeadersInput().element.value).toBe('');
        expect(findByNameAttribute('password').exists()).toBe(false);
      });

      it('when updating an existing profile', () => {
        createComponent({
          propsData: {
            profile: siteProfileWithSecrets,
          },
        });
        expect(findRequestHeadersInput().element.value).toBe(siteProfileWithSecrets.requestHeaders);
        expect(findByNameAttribute('password').element.value).toBe(
          siteProfileWithSecrets.auth.password,
        );
      });

      it('when updating an existing profile with no request-header & password', () => {
        createComponent({
          propsData: {
            profile: { ...siteProfileWithSecrets, requestHeaders: null, auth: { enabled: true } },
          },
        });
        expect(findRequestHeadersInput().element.value).toBe('');
        expect(findByNameAttribute('password').element.value).toBe('');
      });

      it('updating an existing profile with empty submit field as blank', async () => {
        createComponent({
          propsData: {
            profile: {
              ...siteProfileWithSecrets,
              auth: { enabled: true, submitField: 'hello' },
            },
          },
        });
        expect(findByNameAttribute('submitField').element.value).toBe('hello');

        await setFieldValue(findByNameAttribute('submitField'), '');

        expect(findBaseDastProfileForm().props('mutationVariables').auth.submitField).toEqual('');
      });
    });

    it('when updating a profile with empty excludedUrls', async () => {
      createComponent({
        propsData: {
          profile: {
            ...siteProfileWithSecrets,
            excludedUrls: ['url1', 'url2'],
          },
        },
      });

      expect(findExcludedUrlsInput().element.value).toBe('url1,url2');

      await setFieldValue(findExcludedUrlsInput(), '');

      expect(findBaseDastProfileForm().props('mutationVariables').excludedUrls).toEqual([]);
    });

    describe('when target type is API', () => {
      const getScanMethodOption = (index) => {
        return findScanMethodInput().findAll('option').at(index);
      };
      const setScanMethodOption = (index) => {
        getScanMethodOption(index).setSelected();
        findScanMethodInput().trigger('change');
      };

      beforeEach(() => {
        setTargetType(TARGET_TYPES.API.value);
      });

      it('should show the auth section', () => {
        expect(findAuthSection().exists()).toBe(true);
      });

      describe('scan method option', () => {
        it('should render all scan method options', () => {
          expect(findScanMethodInput().exists()).toBe(true);
          expect(getScanMethodOption(0).attributes('disabled')).toBeDefined();
          Object.values(SCAN_METHODS).forEach((method, index) => {
            expect(getScanMethodOption(index + 1).text()).toBe(method.text);
          });
        });

        it('should not show scan file-path input by default', () => {
          expect(scanFilePathInput().exists()).toBe(false);
        });

        it('should show scan file-path input upon selection', async () => {
          await setScanMethodOption(1);
          expect(scanFilePathInput().exists()).toBe(true);
          expect(findGraphQlHelpText().exists()).toBe(false);
        });

        it('should display graphql help text only for graphql option', async () => {
          await setScanMethodOption(2);
          expect(scanFilePathInput().exists()).toBe(true);
          expect(findGraphQlHelpText().exists()).toBe(true);
        });
      });

      describe.each`
        title                  | profile                   | mutationVars                         | mutation                         | mutationKind
        ${'New site profile'}  | ${{}}                     | ${{ fullPath: projectFullPath }}     | ${dastSiteProfileCreateMutation} | ${'dastSiteProfileCreate'}
        ${'Edit site profile'} | ${siteProfileWithSecrets} | ${{ id: siteProfileWithSecrets.id }} | ${dastSiteProfileUpdateMutation} | ${'dastSiteProfileUpdate'}
      `('$title', ({ profile, mutationVars, mutation, mutationKind }) => {
        beforeEach(async () => {
          createComponent({
            propsData: {
              profile,
            },
          });
          await waitForPromises();
        });

        it('passes correct props to base component', async () => {
          await fillForm();
          await setTargetType(TARGET_TYPES.API.value);
          await setScanMethodOption(1);
          await setFieldValue(scanFilePathInput(), scanFilePath);

          const baseDastProfileForm = findBaseDastProfileForm();
          expect(baseDastProfileForm.props('mutation')).toBe(mutation);
          expect(baseDastProfileForm.props('mutationType')).toBe(mutationKind);
          expect(baseDastProfileForm.props('mutationVariables')).toEqual(
            expect.objectContaining(mutationVars),
          );
        });
      });
    });
  });

  describe.each`
    title                  | profile                   | mutationVars                         | mutationKind
    ${'New site profile'}  | ${{}}                     | ${{}}                                | ${'dastSiteProfileCreate'}
    ${'Edit site profile'} | ${siteProfileWithSecrets} | ${{ id: siteProfileWithSecrets.id }} | ${'dastSiteProfileUpdate'}
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
      expect(findProfileNameInput().element.value).toBe(
        (profile?.name || profile?.profileName) ?? '',
      );
    });

    it('passes props vars to base component', () => {
      const baseDastProfileForm = findBaseDastProfileForm();
      expect(baseDastProfileForm.props('mutationType')).toBe(mutationKind);
      expect(baseDastProfileForm.props('mutationVariables')).toEqual(
        expect.objectContaining(mutationVars),
      );
    });
  });

  describe('when profile does not come from a policy', () => {
    beforeEach(() => {
      createShallowComponent({
        propsData: {
          profile: siteProfileWithSecrets,
        },
      });
    });

    it('should enable all form groups', () => {
      expect(findParentFormGroup().attributes('disabled')).toBe(undefined);
    });
  });

  describe('when profile does comes from a policy', () => {
    beforeEach(() => {
      createShallowComponent({
        propsData: {
          profile: policySiteProfiles[0],
        },
      });
    });

    it('should disable all form groups', () => {
      expect(findParentFormGroup().attributes('disabled')).toBeDefined();
    });
  });

  describe('when profile is used in yaml config', () => {
    beforeEach(() => {
      createShallowComponent({
        propsData: {
          isProfileInUse: true,
        },
      });
    });

    it('should disable the profile name field', () => {
      expect(findProfileNameInput().attributes('disabled')).toBeDefined();
    });
  });
});
