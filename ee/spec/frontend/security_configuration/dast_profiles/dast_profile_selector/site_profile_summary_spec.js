import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { merge } from 'lodash';
import * as responses from 'ee_jest/security_configuration/dast_profiles/mocks/apollo_mock';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import App from 'ee/security_configuration/dast_profiles/dast_profile_selector/site_profile_summary.vue';
import { siteProfiles } from 'ee_jest/security_configuration/dast_profiles/mocks/mock_data';
import DastSiteValidationModal from 'ee/security_configuration/dast_site_validation/components/dast_site_validation_modal.vue';
import DastProfileSummaryCard from 'ee/security_configuration/dast_profiles/dast_profile_selector/dast_profile_summary_card.vue';
import {
  DAST_SITE_VALIDATION_STATUS,
  DAST_SITE_VALIDATION_POLLING_INTERVAL,
} from 'ee/security_configuration/dast_site_validation/constants';
import { updateSiteProfilesStatuses } from 'ee/security_configuration/dast_profiles/graphql/cache_utils';
import dastSiteValidationsQuery from 'ee/security_configuration/dast_site_validation/graphql/dast_site_validations.query.graphql';
import createApolloProvider from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('ee/security_configuration/dast_profiles/graphql/cache_utils', () => ({
  updateSiteProfilesStatuses: jest.fn(),
}));

const [profile] = siteProfiles;
const projectPath = 'group/project';
const scanMethodOption = {
  scanMethod: 'OPENAPI',
  scanFilePath: 'https://example.com',
};

describe('DastScannerProfileSummary', () => {
  let wrapper;
  let requestHandlers;
  let apolloProvider;

  const defaultProps = {
    profile: {
      ...profile,
      ...scanMethodOption,
    },
  };

  const defaultProvide = {
    projectPath,
  };

  const createMockApolloProvider = (handlers) => {
    Vue.use(VueApollo);
    requestHandlers = handlers;
    return createApolloProvider([[dastSiteValidationsQuery, requestHandlers.dastSiteValidations]]);
  };

  const createComponentFactory = (mountFn = shallowMountExtended) => (options = {}, handlers) => {
    apolloProvider = handlers && createMockApolloProvider(handlers);
    wrapper = mountFn(
      App,
      merge(
        {
          propsData: defaultProps,
          provide: defaultProvide,
          stubs: {
            DastProfileSummaryCard,
          },
        },
        { ...options, apolloProvider },
      ),
    );
  };

  const createComponent = createComponentFactory();
  const createFullComponent = createComponentFactory(mountExtended);

  const findValidateButton = () => wrapper.findByTestId('validation-button');
  const findModal = () => wrapper.findComponent(DastSiteValidationModal);

  const getProfileByStatus = (validationType) => {
    return siteProfiles.find(({ validationStatus }) => validationStatus === validationType);
  };

  it('renders properly', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  describe('Validation Button', () => {
    it.each`
      status      | statusEnum                            | buttonLabel
      ${'no'}     | ${DAST_SITE_VALIDATION_STATUS.NONE}   | ${'Validate'}
      ${'failed'} | ${DAST_SITE_VALIDATION_STATUS.FAILED} | ${'Retry'}
    `(
      'profile with $status validation should show $buttonLabel button',
      ({ statusEnum, buttonLabel }) => {
        createComponent({ propsData: { profile: getProfileByStatus(statusEnum) } });

        expect(findValidateButton().exists()).toBe(true);
        expect(findValidateButton().text()).toBe(buttonLabel);
      },
    );

    it.each`
      status           | statusEnum
      ${'pending'}     | ${DAST_SITE_VALIDATION_STATUS.PENDING}
      ${'in-progress'} | ${DAST_SITE_VALIDATION_STATUS.INPROGRESS}
      ${'passed'}      | ${DAST_SITE_VALIDATION_STATUS.PASSED}
    `('profile with $status validation should not show validation button', ({ statusEnum }) => {
      createComponent({ propsData: { profile: getProfileByStatus(statusEnum) } });

      expect(findValidateButton().exists()).toBe(false);
    });

    it('should render modal when clicked', async () => {
      createFullComponent({
        propsData: { profile: getProfileByStatus(DAST_SITE_VALIDATION_STATUS.NONE) },
      });

      findValidateButton().vm.$emit('click');
      await nextTick();

      expect(findModal().exists()).toBe(true);
    });

    describe('Polling', () => {
      beforeEach(() => {
        createFullComponent(
          { propsData: { profile } },
          {
            dastSiteValidations: jest.fn().mockResolvedValue(
              responses.dastSiteValidations([
                {
                  normalizedTargetUrl: profile.normalizedTargetUrl,
                  status: DAST_SITE_VALIDATION_STATUS.FAILED,
                  validationStartedAt: '2022-10-31T15:47:21Z',
                },
              ]),
            ),
          },
        );
      });

      it('fetches validation statuses and updates the cache', async () => {
        await waitForPromises();

        expect(requestHandlers.dastSiteValidations).toHaveBeenCalledWith({
          fullPath: projectPath,
          urls: [profile.normalizedTargetUrl],
        });

        expect(updateSiteProfilesStatuses).toHaveBeenCalledTimes(1);
        expect(updateSiteProfilesStatuses).toHaveBeenCalledWith({
          fullPath: projectPath,
          normalizedTargetUrl: profile.normalizedTargetUrl,
          store: apolloProvider.defaultClient,
          status: DAST_SITE_VALIDATION_STATUS.FAILED,
        });
      });

      it(`sets correct polling`, () => {
        const apolloQuery = wrapper.vm.$apollo.queries.validations;
        expect(apolloQuery.options.pollInterval).toBe(DAST_SITE_VALIDATION_POLLING_INTERVAL);
      });
    });
  });
});
