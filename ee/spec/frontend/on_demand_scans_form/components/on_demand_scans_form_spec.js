import { GlForm, GlFormInput } from '@gitlab/ui';
import { createLocalVue } from '@vue/test-utils';
import { merge } from 'lodash';
import VueApollo from 'vue-apollo';
import { nextTick } from 'vue';
import siteProfilesFixtures from 'test_fixtures/graphql/security_configuration/dast_profiles/graphql/dast_site_profiles.query.graphql.basic.json';
import scannerProfilesFixtures from 'test_fixtures/graphql/security_configuration/dast_profiles/graphql/dast_scanner_profiles.query.graphql.basic.json';
import OnDemandScansForm from 'ee/on_demand_scans_form/components/on_demand_scans_form.vue';
import ScanSchedule from 'ee/on_demand_scans_form/components/scan_schedule.vue';
import ConfigurationPageLayout from 'ee/security_configuration/components/configuration_page_layout.vue';
import SectionLayout from '~/vue_shared/security_configuration/components/section_layout.vue';
import SectionLoader from '~/vue_shared/security_configuration/components/section_loader.vue';
import dastProfileCreateMutation from 'ee/on_demand_scans_form/graphql/dast_profile_create.mutation.graphql';
import dastProfileUpdateMutation from 'ee/on_demand_scans_form/graphql/dast_profile_update.mutation.graphql';
import dastScannerProfilesQuery from 'ee/security_configuration/dast_profiles/graphql/dast_scanner_profiles.query.graphql';
import dastSiteProfilesQuery from 'ee/security_configuration/dast_profiles/graphql/dast_site_profiles.query.graphql';
import createApolloProvider from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import { redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import RefSelector from '~/ref/components/ref_selector.vue';
import PreScanVerificationConfigurator from 'ee/security_configuration/dast_pre_scan_verification/components/pre_scan_verification_configurator.vue';
import DastProfilesConfigurator from 'ee/security_configuration/dast_profiles/dast_profiles_configurator/dast_profiles_configurator.vue';

import {
  siteProfiles,
  scannerProfiles,
  nonValidatedSiteProfile,
  validatedSiteProfile,
} from 'ee_jest/security_configuration/dast_profiles/mocks/mock_data';

const dastSiteValidationDocsPath = '/application_security/dast/index#dast-site-validation';
const projectPath = 'group/project';
const defaultBranch = 'main';
const selectedBranch = 'some-other-branch';
const onDemandScansPath = '/on_demand_scans#saved';
const scannerProfilesLibraryPath = '/security/configuration/profile_library#scanner-profiles';
const siteProfilesLibraryPath = '/security/configuration/profile_library#site-profiles';
const newScannerProfilePath = '/security/configuration/profile_library/dast_scanner_profile/new';
const newSiteProfilePath = `/${projectPath}/-/security/configuration/profile_library`;
const pipelineUrl = `/${projectPath}/pipelines/123`;
const editPath = `/${projectPath}/on_demand_scans_form/1/edit`;
const [passiveScannerProfile, activeScannerProfile] = scannerProfiles;
const dastScan = {
  id: 1,
  branch: { name: 'dev' },
  name: 'My daily scan',
  description: 'Tests for SQL injections',
  dastScannerProfile: { id: passiveScannerProfile.id },
  dastSiteProfile: { id: validatedSiteProfile.id },
};

jest.mock('~/lib/utils/url_utility', () => {
  return {
    ...jest.requireActual('~/lib/utils/url_utility'),
    redirectTo: jest.fn(),
  };
});

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

  const findForm = () => wrapper.findComponent(GlForm);
  const findHelpPageLink = () => wrapper.findByTestId('help-page-link');
  const findNameInput = () => wrapper.findByTestId('dast-scan-name-input');
  const findBranchInput = () => wrapper.findByTestId('dast-scan-branch-input');
  const findDescriptionInput = () => wrapper.findByTestId('dast-scan-description-input');
  const findAlert = () => wrapper.findByTestId('on-demand-scan-error');
  const findProfilesConflictAlert = () =>
    wrapper.findByTestId('on-demand-scans-profiles-conflict-alert');
  const findSubmitButton = () => wrapper.findByTestId('on-demand-scan-submit-button');
  const findSaveButton = () => wrapper.findByTestId('on-demand-scan-save-button');
  const findRunnerTagsFormGroup = () => wrapper.findByTestId('on-demand-scan-runner-tags');
  const findCancelButton = () => wrapper.findByTestId('on-demand-scan-cancel-button');
  const findDastProfilesConfigurator = () => wrapper.findComponent(DastProfilesConfigurator);
  const findPreScanVerificationConfigurator = () =>
    wrapper.findComponent(PreScanVerificationConfigurator);

  const hasSiteProfileAttributes = () => {
    expect(findDastProfilesConfigurator().props('savedProfiles')).toEqual(dastScan);
  };

  const setValidFormData = async () => {
    findNameInput().vm.$emit('input', 'My daily scan');
    findBranchInput().vm.$emit('input', selectedBranch);
    await findDastProfilesConfigurator().vm.$emit('profiles-selected', {
      scannerProfile: passiveScannerProfile,
      siteProfile: nonValidatedSiteProfile,
    });
    await nextTick();
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

  const submitForm = () => findForm().vm.$emit('submit', { preventDefault: () => {} });
  const saveScan = () => findSaveButton().vm.$emit('click');

  const createMockApolloProvider = (handlers) => {
    localVue.use(VueApollo);

    requestHandlers = {
      dastScannerProfiles: jest.fn().mockResolvedValue(scannerProfilesFixtures),
      dastSiteProfiles: jest.fn().mockResolvedValue(siteProfilesFixtures),
      ...handlers,
    };

    return createApolloProvider([
      [dastScannerProfilesQuery, requestHandlers.dastScannerProfiles],
      [dastSiteProfilesQuery, requestHandlers.dastSiteProfiles],
    ]);
  };

  const createComponentFactory = (mountFn = shallowMountExtended) => (
    options = {},
    withHandlers,
    glFeatures = {},
  ) => {
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
          propsData: {
            defaultBranch,
          },
          mocks: defaultMocks,
          provide: {
            canEditRunnerTags: true,
            projectPath,
            onDemandScansPath,
            scannerProfilesLibraryPath,
            siteProfilesLibraryPath,
            newScannerProfilePath,
            newSiteProfilePath,
            dastSiteValidationDocsPath,
            ...glFeatures,
          },
          stubs: {
            GlFormInput: GlFormInputStub,
            RefSelector: RefSelectorStub,
            ScanSchedule: true,
            SectionLayout,
            SectionLoader,
            ConfigurationPageLayout,
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
    return wrapper;
  };
  const createComponent = createComponentFactory(mountExtended);
  const createShallowComponent = createComponentFactory();

  it('should have correct component rendered', () => {
    createShallowComponent();
    expect(findDastProfilesConfigurator().exists()).toBe(true);
  });

  describe('when creating a new scan', () => {
    it('renders properly', () => {
      createComponent();

      expect(wrapper.text()).toContain('New on-demand scan');
      expect(wrapper.findComponent(ScanSchedule).exists()).toBe(true);
    });

    it('renders a link to the docs', () => {
      createComponent();
      const link = findHelpPageLink();

      expect(link.exists()).toBe(true);
      expect(link.attributes('href')).toBe(
        '/help/user/application_security/dast/index#on-demand-scans',
      );
    });

    it('populates the branch input with the default branch', () => {
      createComponent();

      expect(findBranchInput().props('value')).toBe(defaultBranch);
    });
  });

  describe('when editing an existing scan', () => {
    describe('when the branch is not present', () => {
      /**
       * It is possible for pre-fetched data not to have a branch, so we must
       * handle this path.
       */
      beforeEach(() => {
        createShallowComponent({
          propsData: {
            ...dastScan,
            branch: null,
          },
        });
      });

      it('sets the branch to the default', () => {
        expect(findBranchInput().props('value')).toBe(defaultBranch);
      });
    });

    describe('when the branch is present', () => {
      beforeEach(() => {
        createShallowComponent({
          propsData: {
            dastScan,
          },
        });
      });

      it('sets the title properly', () => {
        expect(wrapper.text()).toContain('Edit on-demand scan');
      });

      it('populates the fields with passed values', () => {
        expect(findNameInput().attributes('value')).toBe(dastScan.name);
        expect(findBranchInput().props('value')).toBe(dastScan.branch.name);
        expect(findDescriptionInput().attributes('value')).toBe(dastScan.description);
        hasSiteProfileAttributes();
      });
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
      ${'save'}   | ${saveScan}    | ${false}            | ${true}           | ${false} | ${onDemandScansPath}
    `(
      'on $action',
      ({ actionFunction, submitButtonLoading, saveButtonLoading, runAfter, redirectPath }) => {
        describe('with valid form data', () => {
          beforeEach(async () => {
            createShallowComponent();
            await setupSuccess();
            actionFunction();
          });

          it('sets correct button states', () => {
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
                  branchName: selectedBranch,
                  dastScannerProfileId: passiveScannerProfile.id,
                  dastSiteProfileId: nonValidatedSiteProfile.id,
                  fullPath: projectPath,
                  runAfterCreate: runAfter,
                  tagList: [],
                },
              },
            });
          });

          it('redirects to the URL provided in the response', () => {
            expect(redirectTo).toHaveBeenCalledWith(redirectPath); // eslint-disable-line import/no-deprecated
          });

          it('does not show an alert', () => {
            expect(findAlert().exists()).toBe(false);
          });
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

          it('passes the scan ID to the profile selectors', () => {
            hasSiteProfileAttributes();
          });

          it(`triggers dastProfileUpdateMutation mutation with runAfterUpdate set to ${runAfter}`, () => {
            expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
              mutation: dastProfileUpdateMutation,
              variables: {
                input: {
                  id: 1,
                  name: 'My daily scan',
                  branchName: selectedBranch,
                  description: 'Tests for SQL injections',
                  dastScannerProfileId: passiveScannerProfile.id,
                  dastSiteProfileId: nonValidatedSiteProfile.id,
                  runAfterUpdate: runAfter,
                  tagList: [],
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

      beforeEach(() => {
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

    it('redirects to profiles library', () => {
      expect(redirectTo).toHaveBeenCalledWith(onDemandScansPath); // eslint-disable-line import/no-deprecated
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
      const setFormData = async () => {
        await findDastProfilesConfigurator().vm.$emit('profiles-selected', {
          scannerProfile: selectedScannerProfile,
          siteProfile: selectedSiteProfile,
        });
        await nextTick();
      };

      const testDescription = hasConflict
        ? `warns about conflicting profiles when user selects ${description}`
        : `does not report any conflict when user selects ${description}`;
      it(`${testDescription}`, async () => {
        createShallowComponent();
        await setFormData();

        expect(findProfilesConflictAlert().exists()).toBe(hasConflict);
        expect(findSubmitButton().props('disabled')).toBe(hasConflict);
      });
    },
  );

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

  describe('Dast pre-scan verification', () => {
    it.each`
      featureFlag | expectedResult
      ${true}     | ${true}
      ${false}    | ${false}
    `('should render pre-scan verification configurator', ({ featureFlag, expectedResult }) => {
      createShallowComponent({}, false, {
        glFeatures: {
          dastPreScanVerification: featureFlag,
        },
      });

      expect(findPreScanVerificationConfigurator().exists()).toBe(expectedResult);
    });
  });

  describe('toggle sidebars', () => {
    beforeEach(() => {
      createShallowComponent({}, false, {
        glFeatures: {
          dastPreScanVerification: true,
        },
      });
    });

    it('should close toggle sidebars when one sidebar opens', async () => {
      findPreScanVerificationConfigurator().vm.$emit('open-drawer');
      await nextTick();

      expect(findDastProfilesConfigurator().props('open')).toBe(false);
      expect(findPreScanVerificationConfigurator().props('open')).toBe(true);

      findDastProfilesConfigurator().vm.$emit('open-drawer');
      await nextTick();

      expect(findDastProfilesConfigurator().props('open')).toBe(true);
      expect(findPreScanVerificationConfigurator().props('open')).toBe(false);
    });
  });

  describe('editing rights for regular users', () => {
    it('should be disabled for non-administrative users', () => {
      createComponent(
        {
          provide: {
            canEditRunnerTags: false,
          },
        },
        false,
        {
          glFeatures: {
            onDemandScansRunnerTags: true,
          },
        },
      );

      expect(findRunnerTagsFormGroup().text()).toContain(
        'Only project owners and maintainers can select runner tags',
      );
    });
  });
});
