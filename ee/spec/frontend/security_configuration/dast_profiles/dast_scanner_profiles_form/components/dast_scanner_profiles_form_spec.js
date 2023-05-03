import { GlForm } from '@gitlab/ui';
import { within } from '@testing-library/dom';
import merge from 'lodash/merge';
import BaseDastProfileForm from 'ee/security_configuration/dast_profiles/components/base_dast_profile_form.vue';
import DastScannerProfileForm from 'ee/security_configuration/dast_profiles/dast_scanner_profiles/components/dast_scanner_profile_form.vue';
import { SCAN_TYPE } from 'ee/security_configuration/dast_profiles/dast_scanner_profiles/constants';
import dastScannerProfileCreateMutation from 'ee/security_configuration/dast_profiles/dast_scanner_profiles/graphql/dast_scanner_profile_create.mutation.graphql';
import dastScannerProfileUpdateMutation from 'ee/security_configuration/dast_profiles/dast_scanner_profiles/graphql/dast_scanner_profile_update.mutation.graphql';
import {
  scannerProfiles,
  policyScannerProfiles,
} from 'ee_jest/security_configuration/dast_profiles/mocks/mock_data';
import { TEST_HOST } from 'helpers/test_constants';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';

const projectFullPath = 'group/project';
const profilesLibraryPath = `${TEST_HOST}/${projectFullPath}/-/security/configuration/profile_library`;
const onDemandScansPath = `${TEST_HOST}/${projectFullPath}/-/on_demand_scans`;
const defaultProfile = scannerProfiles[0];

const {
  profileName,
  spiderTimeout,
  targetTimeout,
  scanType,
  useAjaxSpider,
  showDebugMessages,
} = defaultProfile;

const defaultProps = {
  profilesLibraryPath,
  onDemandScansPath,
  projectFullPath,
};

describe('DastScannerProfileForm', () => {
  let wrapper;

  const withinComponent = () => within(wrapper.element);

  const findBaseDastProfileForm = () => wrapper.findComponent(BaseDastProfileForm);
  const findParentFormGroup = () => wrapper.findByTestId('dast-scanner-parent-group');
  const findForm = () => wrapper.findComponent(GlForm);
  const findProfileNameInput = () => wrapper.findByTestId('profile-name-input');
  const findSpiderTimeoutInput = () => wrapper.findByTestId('spider-timeout-input');
  const findTargetTimeoutInput = () => wrapper.findByTestId('target-timeout-input');
  const findScanType = () => wrapper.findByTestId('scan-type-option');

  const setFieldValue = async (field, value) => {
    await field.find('input').setValue(value);
    field.trigger('blur');
  };

  const createComponentFactory = (mountFn = mountExtended) => (options) => {
    wrapper = mountFn(
      DastScannerProfileForm,
      merge(
        {},
        {
          propsData: defaultProps,
          mocks: {
            $apollo: {
              mutate: jest.fn(),
            },
          },
        },
        options,
      ),
    );
  };
  const createShallowComponent = createComponentFactory(shallowMountExtended);
  const createComponent = createComponentFactory();

  it('form renders properly', () => {
    createComponent();
    expect(findForm().exists()).toBe(true);
    expect(findForm().text()).toContain('New scanner profile');
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

  describe.each`
    timeoutType | finder                    | invalidValues | validValue
    ${'Spider'} | ${findSpiderTimeoutInput} | ${[-1, 2881]} | ${spiderTimeout}
    ${'Target'} | ${findTargetTimeoutInput} | ${[0, 3601]}  | ${targetTimeout}
  `('$timeoutType Timeout', ({ finder, invalidValues, validValue }) => {
    const errorMessage = 'Constraints not satisfied';

    beforeEach(() => {
      createComponent();
    });

    it.each(invalidValues)('is marked as invalid provided an invalid value', async (value) => {
      await setFieldValue(finder().find('input'), value);
      expect(wrapper.text()).toContain(errorMessage);
    });

    it('is marked as valid provided a valid value', async () => {
      await setFieldValue(finder().find('input'), validValue);
      expect(wrapper.text()).not.toContain(errorMessage);
    });

    it('should allow only numbers', () => {
      expect(finder().find('input').props('type')).toBe('number');
    });
  });

  describe.each`
    title                     | profile           | mutation                            | mutationVars                     | mutationKind
    ${'New scanner profile'}  | ${{}}             | ${dastScannerProfileCreateMutation} | ${{ fullPath: projectFullPath }} | ${'dastScannerProfileCreate'}
    ${'Edit scanner profile'} | ${defaultProfile} | ${dastScannerProfileUpdateMutation} | ${{ id: defaultProfile.id }}     | ${'dastScannerProfileUpdate'}
  `('$title', ({ profile, title, mutation, mutationVars, mutationKind }) => {
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

    it('populates the fields with the data passed in via the profile prop or default values', () => {
      expect(findProfileNameInput().element.value).toBe(profile?.profileName ?? '');
      expect(findScanType().vm.$attrs.checked).toBe(profile?.scanType ?? SCAN_TYPE.PASSIVE);
      expect(findSpiderTimeoutInput().props('value')).toBe(profile?.spiderTimeout ?? 1);
      expect(findTargetTimeoutInput().props('value')).toBe(profile?.targetTimeout ?? 60);
    });

    it('passes correct props to base component', async () => {
      await findProfileNameInput().vm.$emit('input', profileName);
      await findSpiderTimeoutInput().vm.$emit('input', spiderTimeout);
      await findTargetTimeoutInput().vm.$emit('input', targetTimeout);

      const baseDastProfileForm = findBaseDastProfileForm();
      expect(baseDastProfileForm.props('mutation')).toBe(mutation);
      expect(baseDastProfileForm.props('mutationType')).toBe(mutationKind);
      expect(baseDastProfileForm.props('mutationVariables')).toEqual({
        profileName,
        spiderTimeout,
        targetTimeout,
        scanType,
        useAjaxSpider,
        showDebugMessages,
        ...mutationVars,
      });
    });
  });

  describe('when profile does not come from a policy', () => {
    beforeEach(() => {
      createShallowComponent({
        propsData: {
          profile: defaultProfile,
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
          profile: policyScannerProfiles[0],
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
