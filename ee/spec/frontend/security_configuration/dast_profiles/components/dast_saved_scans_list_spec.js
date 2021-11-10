import { mount, shallowMount } from '@vue/test-utils';
import { merge } from 'lodash';
import { ERROR_RUN_SCAN, ERROR_MESSAGES } from 'ee/on_demand_scans_form/settings';
import ProfilesList from 'ee/security_configuration/dast_profiles/components/dast_profiles_list.vue';
import Component from 'ee/security_configuration/dast_profiles/components/dast_saved_scans_list.vue';
import DastScanBranch from 'ee/security_configuration/dast_profiles/components/dast_scan_branch.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import { redirectTo } from '~/lib/utils/url_utility';
import { savedScans } from '../mocks/mock_data';

jest.mock('~/lib/utils/url_utility');
jest.mock('~/flash');

describe('EE - DastSavedScansList', () => {
  let wrapper;

  const defaultProps = {
    profiles: [],
    tableLabel: 'Saved scans',
    fields: [
      { key: 'name' },
      { key: 'dastSiteProfile.targetUrl' },
      { key: 'dastScannerProfile.scanType' },
    ],
    profilesPerPage: 10,
    errorMessage: '',
    errorDetails: [],
    noProfilesMessage: 'No scans saved yet',
    fullPath: '/namespace/project',
    hasMoreProfilesToLoad: false,
    isLoading: false,
  };

  const wrapperFactory = (mountFn = shallowMount) => (options = {}) => {
    wrapper = extendedWrapper(
      mountFn(
        Component,
        merge(
          {
            propsData: defaultProps,
          },
          options,
        ),
      ),
    );
  };
  const createFullComponent = wrapperFactory(mount);

  const findProfileList = () => wrapper.findComponent(ProfilesList);

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders profile list properly', () => {
    createFullComponent({
      propsData: { profiles: savedScans },
    });

    expect(findProfileList().exists()).toBe(true);
  });

  it('renders branch information for each profile', () => {
    createFullComponent({
      propsData: { profiles: savedScans },
    });

    expect(wrapper.findAll(DastScanBranch)).toHaveLength(savedScans.length);
  });

  it('passes down the props properly', () => {
    createFullComponent();

    expect(findProfileList().props()).toEqual(defaultProps);
  });

  it('sets listeners on profile list component', () => {
    const inputHandler = jest.fn();
    createFullComponent({
      listeners: {
        input: inputHandler,
      },
    });
    findProfileList().vm.$emit('input');

    expect(inputHandler).toHaveBeenCalled();
  });

  describe('run scan', () => {
    const pipelineUrl = '/pipeline/url';
    const successHandler = jest.fn().mockResolvedValue({
      data: {
        dastProfileRun: {
          pipelineUrl,
          errors: [],
        },
      },
    });

    it('puts the clicked button in the loading state and disabled other buttons', async () => {
      createFullComponent({
        propsData: { profiles: savedScans },
        mocks: {
          $apollo: {
            mutate: successHandler,
          },
        },
      });
      const buttons = wrapper.findAll('[data-testid="dast-scan-run-button"]');

      expect(buttons.at(0).props('loading')).toBe(false);
      expect(buttons.at(1).props('disabled')).toBe(false);

      await buttons.at(0).trigger('click');

      expect(buttons.at(0).props('loading')).toBe(true);
      expect(buttons.at(1).props('disabled')).toBe(true);
    });

    it('redirects to the running pipeline page on success', async () => {
      createFullComponent({
        propsData: { profiles: savedScans },
        mocks: {
          $apollo: {
            mutate: successHandler,
          },
        },
      });
      wrapper.findByTestId('dast-scan-run-button').trigger('click');
      await waitForPromises();

      expect(redirectTo).toHaveBeenCalledWith(pipelineUrl);
      expect(createFlash).not.toHaveBeenCalled();
    });

    it('passes the error message down to the list on failure but does not block errors passed by the parent', async () => {
      const initialErrorMessage = 'Initial error message';
      const finalErrorMessage = 'Final error message';

      createFullComponent({
        propsData: {
          profiles: savedScans,
          errorMessage: initialErrorMessage,
        },
        mocks: {
          $apollo: {
            mutate: jest.fn().mockRejectedValue(),
          },
        },
      });
      const profilesList = findProfileList();

      expect(profilesList.props('errorMessage')).toBe(initialErrorMessage);

      wrapper.findByTestId('dast-scan-run-button').trigger('click');
      await waitForPromises();

      expect(profilesList.props('errorMessage')).toBe(ERROR_MESSAGES[ERROR_RUN_SCAN]);
      expect(redirectTo).not.toHaveBeenCalled();

      await wrapper.setProps({ errorMessage: finalErrorMessage });

      expect(profilesList.props('errorMessage')).toBe(finalErrorMessage);
    });

    it('passes the error message and details down to the list if the API responds with errors-as-data', async () => {
      const errors = ['error-as-data'];
      createFullComponent({
        propsData: { profiles: savedScans },
        mocks: {
          $apollo: {
            mutate: jest.fn().mockResolvedValue({
              data: {
                dastProfileRun: {
                  pipelineUrl: null,
                  errors,
                },
              },
            }),
          },
        },
      });
      wrapper.findByTestId('dast-scan-run-button').trigger('click');
      await waitForPromises();

      expect(findProfileList().props('errorMessage')).toBe(ERROR_MESSAGES[ERROR_RUN_SCAN]);
      expect(findProfileList().props('errorDetails')).toBe(errors);
      expect(redirectTo).not.toHaveBeenCalled();
    });
  });
});
