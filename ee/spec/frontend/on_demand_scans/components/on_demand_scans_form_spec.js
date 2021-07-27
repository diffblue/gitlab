import { GlForm, GlFormInput, GlSkeletonLoader } from '@gitlab/ui';
import { shallowMount, mount, createLocalVue } from '@vue/test-utils';
import { merge } from 'lodash';
import VueApollo from 'vue-apollo';
import OnDemandScansForm from 'ee/on_demand_scans/components/on_demand_scans_form.vue';
import ScannerProfileSelector from 'ee/on_demand_scans/components/profile_selector/scanner_profile_selector.vue';
import SiteProfileSelector from 'ee/on_demand_scans/components/profile_selector/site_profile_selector.vue';
import dastProfileCreateMutation from 'ee/on_demand_scans/graphql/dast_profile_create.mutation.graphql';
import dastProfileUpdateMutation from 'ee/on_demand_scans/graphql/dast_profile_update.mutation.graphql';
import dastScannerProfilesQuery from 'ee/security_configuration/dast_profiles/graphql/dast_scanner_profiles.query.graphql';
import dastSiteProfilesQuery from 'ee/security_configuration/dast_profiles/graphql/dast_site_profiles.query.graphql';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import createApolloProvider from 'helpers/mock_apollo_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import { redirectTo } from '~/lib/utils/url_utility';
import RefSelector from '~/ref/components/ref_selector.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import * as responses from '../mocks/apollo_mocks';
import { scannerProfiles, siteProfiles } from '../mocks/mock_data';

const helpPagePath = '/application_security/dast/index#on-demand-scans';
const projectPath = 'group/project';
const defaultBranch = 'main';
const profilesLibraryPath = '/security/configuration/dast_scans';
const scannerProfilesLibraryPath = '/security/configuration/dast_scans#scanner-profiles';
const siteProfilesLibraryPath = '/security/configuration/dast_scans#site-profiles';
const newScannerProfilePath = '/security/configuration/dast_scans/dast_scanner_profile/new';
const newSiteProfilePath = `/${projectPath}/-/security/configuration/dast_scans`;

const defaultProps = {
  helpPagePath,
  projectPath,
  defaultBranch,
};

const pipelineUrl = `/${projectPath}/pipelines/123`;
const editPath = `/${projectPath}/on_demand_scans/1/edit`;
const [passiveScannerProfile, activeScannerProfile] = scannerProfiles;
const [nonValidatedSiteProfile, validatedSiteProfile] = siteProfiles;
const dastScan = {
  id: 1,
  branch: { name: 'dev' },
  name: 'My daily scan',
  description: 'Tests for SQL injections',
  scannerProfileId: passiveScannerProfile.id,
  siteProfileId: validatedSiteProfile.id,
};

useLocalStorageSpy();
jest.mock('~/lib/utils/url_utility', () => ({
  isAbsolute: jest.requireActual('~/lib/utils/url_utility').isAbsolute,
  queryToObject: jest.requireActual('~/lib/utils/url_utility').queryToObject,
  redirectTo: jest.fn(),
}));

const LOCAL_STORAGE_KEY = 'group/project/on-demand-scans-new-form';

describe('OnDemandScansForm', () => {
  let localVue;
  let wrapper;
  let requestHandlers;

  const GlFormInputStub = stubComponent(GlFormInput, {
    template: '<input />',
  });
  const RefSelectorStub = stubComponent(RefSelector, {
    template: '<input />',
  });

  const findForm = () => wrapper.find(GlForm);
  const findByTestId = (testId) => wrapper.find(`[data-testid="${testId}"]`);
  const findNameInput = () => findByTestId('dast-scan-name-input');
  const findBranchInput = () => findByTestId('dast-scan-branch-input');
  const findDescriptionInput = () => findByTestId('dast-scan-description-input');
  const findScannerProfilesSelector = () => wrapper.find(ScannerProfileSelector);
  const findSiteProfilesSelector = () => wrapper.find(SiteProfileSelector);
  const findAlert = () => findByTestId('on-demand-scan-error');
  const findProfilesConflictAlert = () => findByTestId('on-demand-scans-profiles-conflict-alert');
  const findSubmitButton = () => findByTestId('on-demand-scan-submit-button');
  const findSaveButton = () => findByTestId('on-demand-scan-save-button');
  const findCancelButton = () => findByTestId('on-demand-scan-cancel-button');
  const findProfileSummary = () => findByTestId('selected-profile-summary');

  const setValidFormData = () => {
    findNameInput().vm.$emit('input', 'My daily scan');
    findBranchInput().vm.$emit('input', 'some-other-branch');
    findScannerProfilesSelector().vm.$emit('input', passiveScannerProfile.id);
    findSiteProfilesSelector().vm.$emit('input', nonValidatedSiteProfile.id);
    return wrapper.vm.$nextTick();
  };
  const setupSuccess = ({ edit = false } = {}) => {
    wrapper.vm.$apollo.mutate.mockResolvedValue({
      data: {
        [edit ? 'dastProfileUpdate' : 'dastProfileCreate']: {
          dastProfile: { editPath },
          pipelineUrl,
          errors: [],
        },
      },
    });
    return setValidFormData();
  };
  const selectProfile = (component) => async (profile) => {
    wrapper.find(component).vm.$emit('input', profile.id);
    await wrapper.vm.$nextTick();
  };
  const selectScannerProfile = selectProfile(ScannerProfileSelector);
  const selectSiteProfile = selectProfile(SiteProfileSelector);

  const submitForm = () => findForm().vm.$emit('submit', { preventDefault: () => {} });
  const saveScan = () => findSaveButton().vm.$emit('click');

  const createMockApolloProvider = (handlers) => {
    localVue.use(VueApollo);

    requestHandlers = {
      dastScannerProfiles: jest.fn().mockResolvedValue(responses.dastScannerProfiles()),
      dastSiteProfiles: jest.fn().mockResolvedValue(responses.dastSiteProfiles()),
      ...handlers,
    };
    return createApolloProvider([
      [dastScannerProfilesQuery, requestHandlers.dastScannerProfiles],
      [dastSiteProfilesQuery, requestHandlers.dastSiteProfiles],
    ]);
  };

  const createComponentFactory = (mountFn = shallowMount) => (options = {}, withHandlers) => {
    localVue = createLocalVue();
    let defaultMocks = {
      $apollo: {
        mutate: jest.fn(),
        queries: {
          scannerProfiles: {},
          siteProfiles: {},
        },
        addSmartQuery: jest.fn(),
      },
    };
    let apolloProvider;
    if (withHandlers) {
      apolloProvider = createMockApolloProvider(withHandlers);
      defaultMocks = {};
    }
    wrapper = mountFn(
      OnDemandScansForm,
      merge(
        {},
        {
          propsData: defaultProps,
          mocks: defaultMocks,
          provide: {
            profilesLibraryPath,
            scannerProfilesLibraryPath,
            siteProfilesLibraryPath,
            newScannerProfilePath,
            newSiteProfilePath,
          },
          stubs: {
            GlFormInput: GlFormInputStub,
            RefSelector: RefSelectorStub,
            LocalStorageSync,
          },
        },
        { ...options, localVue, apolloProvider },
        {
          data() {
            return {
              scannerProfiles,
              siteProfiles,
              ...options.data,
            };
          },
        },
      ),
    );
  };
  const createComponent = createComponentFactory(mount);
  const createShallowComponent = createComponentFactory();

  const itClearsLocalStorage = () => {
    it('clears local storage', () => {
      expect(localStorage.removeItem.mock.calls).toEqual([[LOCAL_STORAGE_KEY]]);
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    localStorage.clear();
  });

  describe('when creating a new scan', () => {
    it('renders properly', () => {
      createComponent();

      expect(wrapper.text()).toContain('New on-demand DAST scan');
    });

    it('populates the branch input with the default branch', () => {
      createComponent();

      expect(findBranchInput().props('value')).toBe(defaultBranch);
    });

    it.each`
      scannerProfilesLoading | siteProfilesLoading | isLoading
      ${true}                | ${true}             | ${true}
      ${false}               | ${true}             | ${true}
      ${true}                | ${false}            | ${true}
      ${false}               | ${false}            | ${false}
    `(
      'sets loading state to $isLoading if scanner profiles loading is $scannerProfilesLoading and site profiles loading is $siteProfilesLoading',
      ({ scannerProfilesLoading, siteProfilesLoading, isLoading }) => {
        createShallowComponent({
          mocks: {
            $apollo: {
              queries: {
                scannerProfiles: { loading: scannerProfilesLoading },
                siteProfiles: { loading: siteProfilesLoading },
              },
            },
          },
        });

        expect(wrapper.find(GlSkeletonLoader).exists()).toBe(isLoading);
      },
    );
  });

  describe('when editing an existing scan', () => {
    beforeEach(() => {
      createShallowComponent({
        propsData: {
          dastScan,
        },
      });
    });

    it('sets the title properly', () => {
      expect(wrapper.text()).toContain('Edit on-demand DAST scan');
    });

    it('populates the fields with passed values', () => {
      expect(findNameInput().attributes('value')).toBe(dastScan.name);
      expect(findBranchInput().props('value')).toBe(dastScan.branch.name);
      expect(findDescriptionInput().attributes('value')).toBe(dastScan.description);
      expect(findScannerProfilesSelector().attributes('value')).toBe(dastScan.scannerProfileId);
      expect(findSiteProfilesSelector().attributes('value')).toBe(dastScan.siteProfileId);
    });
  });

  describe('local storage', () => {
    it('get updated when form is modified', async () => {
      createShallowComponent();

      await setValidFormData();

      expect(localStorage.setItem.mock.calls).toEqual([
        [
          LOCAL_STORAGE_KEY,
          JSON.stringify({
            name: 'My daily scan',
            selectedScannerProfileId: 'gid://gitlab/DastScannerProfile/1',
            selectedSiteProfileId: 'gid://gitlab/DastSiteProfile/1',
            selectedBranch: 'some-other-branch',
          }),
        ],
      ]);
    });

    it('reload the form data when available', async () => {
      localStorage.setItem(
        LOCAL_STORAGE_KEY,
        JSON.stringify({
          name: dastScan.name,
          description: dastScan.description,
          selectedScannerProfileId: dastScan.scannerProfileId,
          selectedSiteProfileId: dastScan.siteProfileId,
        }),
      );

      createShallowComponent();
      await wrapper.vm.$nextTick();

      expect(findNameInput().attributes('value')).toBe(dastScan.name);
      expect(findDescriptionInput().attributes('value')).toBe(dastScan.description);
      expect(findScannerProfilesSelector().attributes('value')).toBe(dastScan.scannerProfileId);
      expect(findSiteProfilesSelector().attributes('value')).toBe(dastScan.siteProfileId);
    });
  });

  describe('submit button', () => {
    let submitButton;

    beforeEach(() => {
      createShallowComponent();
      submitButton = findSubmitButton();
    });

    it('is disabled while some fields are empty', () => {
      expect(submitButton.props('disabled')).toBe(true);
    });

    it('becomes enabled when form is valid', async () => {
      await setValidFormData();

      expect(submitButton.props('disabled')).toBe(false);
    });
  });

  describe('submission', () => {
    describe.each`
      action      | actionFunction | submitButtonLoading | saveButtonLoading | runAfter | redirectPath
      ${'submit'} | ${submitForm}  | ${true}             | ${false}          | ${true}  | ${pipelineUrl}
      ${'save'}   | ${saveScan}    | ${false}            | ${true}           | ${false} | ${profilesLibraryPath}
    `(
      'on $action',
      ({ actionFunction, submitButtonLoading, saveButtonLoading, runAfter, redirectPath }) => {
        describe('with valid form data', () => {
          beforeEach(async () => {
            createShallowComponent();
            await setupSuccess();
            actionFunction();
          });

          it('sets correct button states', async () => {
            const [submitButton, saveButton, cancelButton] = [
              findSubmitButton(),
              findSaveButton(),
              findCancelButton(),
            ];

            expect(submitButton.props('loading')).toBe(submitButtonLoading);
            expect(submitButton.props('disabled')).toBe(!submitButtonLoading);
            expect(saveButton.props('loading')).toBe(saveButtonLoading);
            expect(saveButton.props('disabled')).toBe(!saveButtonLoading);
            expect(cancelButton.props('disabled')).toBe(true);
          });

          it(`triggers dastProfileCreateMutation mutation with runAfterCreate set to ${runAfter}`, () => {
            expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
              mutation: dastProfileCreateMutation,
              variables: {
                input: {
                  name: 'My daily scan',
                  branchName: 'some-other-branch',
                  dastScannerProfileId: passiveScannerProfile.id,
                  dastSiteProfileId: nonValidatedSiteProfile.id,
                  fullPath: projectPath,
                  runAfterCreate: runAfter,
                },
              },
            });
          });

          it('redirects to the URL provided in the response', async () => {
            expect(redirectTo).toHaveBeenCalledWith(redirectPath);
          });

          it('does not show an alert', async () => {
            expect(findAlert().exists()).toBe(false);
          });

          itClearsLocalStorage();
        });

        describe('when editing an existing scan', () => {
          beforeEach(async () => {
            createShallowComponent({
              propsData: {
                dastScan,
              },
            });
            await setupSuccess({ edit: true });
            actionFunction();
          });

          it(`triggers dastProfileUpdateMutation mutation with runAfterUpdate set to ${runAfter}`, async () => {
            expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
              mutation: dastProfileUpdateMutation,
              variables: {
                input: {
                  id: 1,
                  name: 'My daily scan',
                  branchName: 'some-other-branch',
                  description: 'Tests for SQL injections',
                  dastScannerProfileId: passiveScannerProfile.id,
                  dastSiteProfileId: nonValidatedSiteProfile.id,
                  fullPath: projectPath,
                  runAfterUpdate: runAfter,
                },
              },
            });
          });
        });

        it('does not run any mutation if name is empty', () => {
          createShallowComponent();
          setValidFormData();
          findNameInput().vm.$emit('input', '');
          actionFunction();

          expect(wrapper.vm.$apollo.mutate).not.toHaveBeenCalled();
        });
      },
    );

    describe('on top-level error', () => {
      beforeEach(async () => {
        createShallowComponent();
        wrapper.vm.$apollo.mutate.mockRejectedValue();
        await setValidFormData();
        submitForm();
      });

      it('resets loading state', () => {
        expect(wrapper.vm.loading).toBe(false);
      });

      it('shows an alert', () => {
        const alert = findAlert();
        expect(alert.exists()).toBe(true);
        expect(alert.text()).toContain('Could not run the scan. Please try again.');
      });
    });

    describe('on errors as data', () => {
      const submitWithError = async (errors) => {
        wrapper.vm.$apollo.mutate.mockResolvedValue({
          data: { dastProfileCreate: { pipelineUrl: null, errors } },
        });
        await setValidFormData();
        await submitForm();
      };

      beforeEach(async () => {
        createShallowComponent();
      });

      it('resets loading state', async () => {
        await submitWithError(['error']);

        expect(wrapper.vm.loading).toBe(false);
      });

      it('shows an alert with the returned errors', async () => {
        const errors = ['error#1', 'error#2', 'error#3'];
        await submitWithError(errors);
        const alert = findAlert();

        expect(alert.exists()).toBe(true);
        errors.forEach((error) => {
          expect(alert.text()).toContain(error);
        });
      });

      it('properly renders errors containing markup', async () => {
        await submitWithError(['an error <a href="#" data-testid="error-link">with a link</a>']);
        const alert = findAlert();

        expect(alert.text()).toContain('an error with a link');
        expect(alert.find('[data-testid="error-link"]').exists()).toBe(true);
      });
    });
  });

  describe('cancellation', () => {
    beforeEach(() => {
      createShallowComponent();
      findCancelButton().vm.$emit('click');
    });

    itClearsLocalStorage();

    it('redirects to profiles library', () => {
      expect(redirectTo).toHaveBeenCalledWith(profilesLibraryPath);
    });
  });

  describe.each`
    description                                  | selectedScannerProfile   | selectedSiteProfile        | hasConflict
    ${'a passive scan and a non-validated site'} | ${passiveScannerProfile} | ${nonValidatedSiteProfile} | ${false}
    ${'a passive scan and a validated site'}     | ${passiveScannerProfile} | ${validatedSiteProfile}    | ${false}
    ${'an active scan and a non-validated site'} | ${activeScannerProfile}  | ${nonValidatedSiteProfile} | ${true}
    ${'an active scan and a validated site'}     | ${activeScannerProfile}  | ${validatedSiteProfile}    | ${false}
  `(
    'profiles conflict prevention',
    ({ description, selectedScannerProfile, selectedSiteProfile, hasConflict }) => {
      const setFormData = () => {
        wrapper.find(ScannerProfileSelector).vm.$emit('input', selectedScannerProfile.id);
        wrapper.find(SiteProfileSelector).vm.$emit('input', selectedSiteProfile.id);
        return wrapper.vm.$nextTick();
      };

      it(
        hasConflict
          ? `warns about conflicting profiles when user selects ${description}`
          : `does not report any conflict when user selects ${description}`,
        async () => {
          createShallowComponent();
          await setFormData();

          expect(findProfilesConflictAlert().exists()).toBe(hasConflict);
          expect(findSubmitButton().props('disabled')).toBe(hasConflict);
        },
      );
    },
  );

  describe.each`
    profileType  | query                    | selector                  | profiles
    ${'scanner'} | ${'dastScannerProfiles'} | ${ScannerProfileSelector} | ${scannerProfiles}
    ${'site'}    | ${'dastSiteProfiles'}    | ${SiteProfileSelector}    | ${siteProfiles}
  `('when there is a single $profileType profile', ({ query, selector, profiles }) => {
    const [profile] = profiles;

    beforeEach(async () => {
      createShallowComponent(
        {},
        {
          [query]: jest.fn().mockResolvedValue(responses[query]([profile])),
        },
      );

      await waitForPromises();
    });

    it('automatically selects the only available profile', () => {
      expect(wrapper.find(selector).attributes('value')).toBe(profile.id);
    });
  });

  describe('scanner profile summary', () => {
    const [{ id }] = scannerProfiles;

    beforeEach(() => {
      createComponent();
    });

    it('renders profile summary when a valid profile is selected', async () => {
      await selectScannerProfile({ id });

      expect(findProfileSummary().exists()).toBe(true);
    });

    it('does not render the summary provided an invalid profile ID', async () => {
      await selectScannerProfile({ id: 'gid://gitlab/DastScannerProfile/123' });

      expect(findProfileSummary().exists()).toBe(false);
    });
  });

  describe('site profile summary', () => {
    const [{ id }] = siteProfiles;

    beforeEach(() => {
      createComponent();
    });

    it('renders profile summary when a valid profile is selected', async () => {
      await selectSiteProfile({ id });

      expect(findProfileSummary().exists()).toBe(true);
    });

    it('does not render the summary provided an invalid profile ID', async () => {
      await selectSiteProfile({ id: 'gid://gitlab/DastSiteProfile/123' });

      expect(findProfileSummary().exists()).toBe(false);
    });
  });

  describe('populate profiles from query params', () => {
    const [siteProfile] = siteProfiles;
    const [scannerProfile] = scannerProfiles;

    it('scanner profile', () => {
      setWindowLocation('?scanner_profile_id=1');
      createShallowComponent();

      expect(wrapper.find(ScannerProfileSelector).attributes('value')).toBe(scannerProfile.id);
    });

    it('site profile', () => {
      setWindowLocation('?site_profile_id=1');
      createShallowComponent();

      expect(wrapper.find(SiteProfileSelector).attributes('value')).toBe(siteProfile.id);
    });

    it('both scanner & site profile', () => {
      setWindowLocation('?site_profile_id=1&scanner_profile_id=1');
      createShallowComponent();

      expect(wrapper.find(SiteProfileSelector).attributes('value')).toBe(siteProfile.id);
      expect(wrapper.find(ScannerProfileSelector).attributes('value')).toBe(scannerProfile.id);
    });

    it('when local storage data is available', async () => {
      localStorage.setItem(
        LOCAL_STORAGE_KEY,
        JSON.stringify({
          selectedScannerProfileId: dastScan.scannerProfileId,
          selectedSiteProfileId: dastScan.siteProfileId,
        }),
      );

      createShallowComponent();
      await wrapper.vm.$nextTick();

      expect(findScannerProfilesSelector().attributes('value')).toBe(scannerProfile.id);
      expect(findSiteProfilesSelector().attributes('value')).toBe(siteProfile.id);
    });
  });

  describe('when no repository exists', () => {
    beforeEach(() => {
      createShallowComponent({
        propsData: {
          /**
           * The assumption here is that, if a default branch is not defined, then the project
           * does not have a repository.
           */
          defaultBranch: '',
        },
      });
    });

    it('shows an error message', () => {
      expect(wrapper.text()).toContain(
        'You must create a repository within your project to run an on-demand scan.',
      );
    });
  });
});
