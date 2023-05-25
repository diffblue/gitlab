import { GlDisclosureDropdown, GlTabs } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { within } from '@testing-library/dom';
import { mount, shallowMount } from '@vue/test-utils';
import DastFailedSiteValidations from 'ee/security_configuration/dast_profiles/components/dast_failed_site_validations.vue';
import DastProfiles from 'ee/security_configuration/dast_profiles/components/dast_profiles.vue';
import setWindowLocation from 'helpers/set_window_location_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import dastScannerProfilesQuery from 'ee/security_configuration/dast_profiles/graphql/dast_scanner_profiles.query.graphql';
import dastScannerProfilesDelete from 'ee/security_configuration/dast_profiles/graphql/dast_scanner_profiles_delete.mutation.graphql';
import dastSiteProfilesQuery from 'ee/security_configuration/dast_profiles/graphql/dast_site_profiles.query.graphql';
import dastSiteProfilesDelete from 'ee/security_configuration/dast_profiles/graphql/dast_site_profiles_delete.mutation.graphql';
import { TEST_HOST } from 'helpers/test_constants';
import {
  scannerProfilesResponse,
  siteProfilesResponse,
  scannerProfileDeleteResponse,
  siteProfileDeleteResponse,
} from './mock_data/apollo_mock';

const TEST_NEW_DAST_SCANNER_PROFILE_PATH = '/-/on_demand_scans/scanner_profiles/new';
const TEST_NEW_DAST_SITE_PROFILE_PATH = '/-/on_demand_scans/site_profiles/new';
const TEST_PROJECT_FULL_PATH = '/namespace/project';

Vue.use(VueApollo);

beforeEach(() => {
  setWindowLocation(TEST_HOST);
});

describe('EE - DastProfiles', () => {
  let wrapper;

  const defaultHandlers = {
    queries: {
      siteProfiles: jest.fn().mockResolvedValue(siteProfilesResponse()),
      scannerProfiles: jest.fn().mockResolvedValue(scannerProfilesResponse()),
    },
    deletions: {
      siteProfiles: jest.fn().mockResolvedValue(siteProfileDeleteResponse()),
      scannerProfiles: jest.fn().mockResolvedValue(scannerProfileDeleteResponse()),
    },
  };

  const createMockApolloProvider = (handlers) => {
    return createMockApollo([
      [dastSiteProfilesQuery, handlers.queries.siteProfiles],
      [dastScannerProfilesQuery, handlers.queries.scannerProfiles],
      [dastSiteProfilesDelete, handlers.deletions.siteProfiles],
      [dastScannerProfilesDelete, handlers.deletions.scannerProfiles],
    ]);
  };

  const createComponentFactory = (mountFn = shallowMount) => ({
    handlers = defaultHandlers,
  } = {}) => {
    const defaultProps = {
      createNewProfilePaths: {
        scannerProfile: TEST_NEW_DAST_SCANNER_PROFILE_PATH,
        siteProfile: TEST_NEW_DAST_SITE_PROFILE_PATH,
      },
      projectFullPath: TEST_PROJECT_FULL_PATH,
    };

    wrapper = mountFn(DastProfiles, {
      stubs: {
        DastFailedSiteValidations: true,
      },
      propsData: defaultProps,
      apolloProvider: createMockApolloProvider(handlers),
    });
  };

  const createComponent = createComponentFactory();
  const createFullComponent = createComponentFactory(mount);

  const withinComponent = () => within(wrapper.element);
  const getProfilesComponent = (profileType) => wrapper.find(`[data-testid="${profileType}List"]`);
  const getDisclosureComponent = () => wrapper.findComponent(GlDisclosureDropdown);
  const getTabsComponent = () => wrapper.findComponent(GlTabs);
  const getTab = ({ tabName, selected }) =>
    withinComponent().getByRole('tab', {
      name: tabName,
      selected,
    });

  describe('failed validations', () => {
    it('renders the failed site validations summary', () => {
      createComponent();

      expect(wrapper.findComponent(DastFailedSiteValidations).exists()).toBe(true);
    });
  });

  describe('header', () => {
    it('shows a heading that describes the purpose of the page', () => {
      createFullComponent();

      const heading = withinComponent().getByRole('heading', { name: /DAST profile library/i });

      expect(heading).not.toBe(null);
    });

    it('has a "New" dropdown menu', () => {
      createComponent();

      expect(getDisclosureComponent().props('toggleText')).toBe('New');
    });

    it('has a dropdown item that links to form', () => {
      createComponent();

      expect(getDisclosureComponent().props('items')).toMatchObject([
        {
          text: 'Site profile',
          href: TEST_NEW_DAST_SITE_PROFILE_PATH,
          extraAttrs: {
            key: 'siteProfiles',
          },
        },
        {
          text: 'Scanner profile',
          href: TEST_NEW_DAST_SCANNER_PROFILE_PATH,
          extraAttrs: {
            key: 'scannerProfiles',
          },
        },
      ]);
    });
  });

  describe('tabs', () => {
    describe('without location hash set', () => {
      beforeEach(() => {
        createFullComponent();
      });

      it('shows a tab-list that contains the different profile categories', () => {
        const tabList = withinComponent().getByRole('tablist');

        expect(tabList).not.toBe(null);
      });

      it.each`
        tabName               | shouldBeSelectedByDefault
        ${'Site profiles'}    | ${true}
        ${'Scanner profiles'} | ${false}
      `(
        'shows a "$tabName" tab which has "selected" set to "$shouldBeSelectedByDefault"',
        ({ tabName, shouldBeSelectedByDefault }) => {
          const tab = getTab({
            tabName,
            selected: shouldBeSelectedByDefault,
          });

          expect(tab).not.toBe(null);
        },
      );
    });

    describe.each`
      tabName               | index | givenLocationHash
      ${'Site profiles'}    | ${0}  | ${'#site-profiles'}
      ${'Scanner profiles'} | ${1}  | ${'#scanner-profiles'}
    `('with location hash set to "$givenLocationHash"', ({ tabName, index, givenLocationHash }) => {
      beforeEach(() => {
        setWindowLocation(givenLocationHash);
        createFullComponent();
      });

      it(`has "${tabName}" selected`, () => {
        const tab = getTab({
          tabName,
          selected: true,
        });

        expect(tab).not.toBe(null);
      });

      it('updates the browsers URL to contain the selected tab', () => {
        setWindowLocation('#');
        expect(window.location.hash).toBe('');

        getTabsComponent().vm.$emit('input', index);

        expect(window.location.hash).toBe(givenLocationHash);
      });
    });
  });

  it.each`
    profileType          | expectedErrorMessage
    ${'siteProfiles'}    | ${'Could not fetch site profiles. Please refresh the page, or try again later.'}
    ${'scannerProfiles'} | ${'Could not fetch scanner profiles. Please refresh the page, or try again later.'}
  `(
    'passes the correct error message for $profileType',
    async ({ profileType, expectedErrorMessage }) => {
      createComponent({
        handlers: {
          ...defaultHandlers,
          queries: {
            [profileType]: jest.fn().mockRejectedValue(),
          },
        },
      });
      await waitForPromises();

      expect(getProfilesComponent(profileType).attributes('error-message')).toEqual(
        expectedErrorMessage,
      );
    },
  );

  describe.each`
    description                | profileType
    ${'Site Profiles List'}    | ${'siteProfiles'}
    ${'Scanner Profiles List'} | ${'scannerProfiles'}
  `('$description', ({ profileType }) => {
    it('passes down the loading state when loading is true', async () => {
      createComponent();

      await nextTick();
      expect(getProfilesComponent(profileType).attributes('is-loading')).toBe('true');
    });

    it('fetches more results when "@load-more-profiles" is emitted', async () => {
      const queryHandler = defaultHandlers.queries[profileType];

      createComponent();
      await waitForPromises();

      expect(queryHandler).toHaveBeenCalledTimes(1);

      getProfilesComponent(profileType).vm.$emit('load-more-profiles');

      expect(queryHandler).toHaveBeenCalledTimes(2);
    });

    it('deletes profile when "@delete-profile" is emitted', async () => {
      const deletionHandler = defaultHandlers.deletions[profileType];

      createComponent();
      await waitForPromises();

      expect(deletionHandler).not.toHaveBeenCalled();

      getProfilesComponent(profileType).vm.$emit('delete-profile', '1');

      expect(deletionHandler).toHaveBeenCalledTimes(1);
    });

    it('passes on the error details when the delete mutation fails', async () => {
      const errors = ['something went wrong', 'another error'];

      const handlers = {
        siteProfiles: siteProfileDeleteResponse(errors),
        scannerProfiles: scannerProfileDeleteResponse(errors),
      };

      createComponent({
        handlers: {
          ...defaultHandlers,
          deletions: {
            [profileType]: jest.fn().mockResolvedValue(handlers[profileType]),
          },
        },
      });

      await waitForPromises();

      getProfilesComponent(profileType).vm.$emit('delete-profile', '1');

      await waitForPromises();

      expect(getProfilesComponent(profileType).attributes('error-details')).toEqual(
        errors.toString(),
      );
    });

    it('passes on that there are more profiles to be fetched', async () => {
      const handlers = {
        siteProfiles: siteProfilesResponse({ pageInfo: { hasNextPage: true } }),
        scannerProfiles: scannerProfilesResponse({ pageInfo: { hasNextPage: true } }),
      };
      createComponent({
        handlers: {
          ...defaultHandlers,
          queries: {
            [profileType]: jest.fn().mockResolvedValue(handlers[profileType]),
          },
        },
      });

      await waitForPromises();

      expect(getProfilesComponent(profileType).attributes('has-more-profiles-to-load')).toBe(
        'true',
      );
    });
  });
});
