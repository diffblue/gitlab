import { GlDisclosureDropdown, GlTabs } from '@gitlab/ui';
import { within } from '@testing-library/dom';
import { mount, shallowMount } from '@vue/test-utils';
import { merge } from 'lodash';
import { nextTick } from 'vue';
import DastFailedSiteValidations from 'ee/security_configuration/dast_profiles/components/dast_failed_site_validations.vue';
import DastProfiles from 'ee/security_configuration/dast_profiles/components/dast_profiles.vue';
import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'helpers/test_constants';

const TEST_NEW_DAST_SCANNER_PROFILE_PATH = '/-/on_demand_scans/scanner_profiles/new';
const TEST_NEW_DAST_SITE_PROFILE_PATH = '/-/on_demand_scans/site_profiles/new';
const TEST_PROJECT_FULL_PATH = '/namespace/project';

beforeEach(() => {
  setWindowLocation(TEST_HOST);
});

describe('EE - DastProfiles', () => {
  let wrapper;

  const createComponentFactory = (mountFn = shallowMount) => (options = {}) => {
    const defaultProps = {
      createNewProfilePaths: {
        scannerProfile: TEST_NEW_DAST_SCANNER_PROFILE_PATH,
        siteProfile: TEST_NEW_DAST_SITE_PROFILE_PATH,
      },
      projectFullPath: TEST_PROJECT_FULL_PATH,
    };

    const defaultMocks = {
      $apollo: {
        queries: {
          dastProfiles: {
            fetchMore: jest.fn().mockResolvedValue(),
          },
          siteProfiles: {
            fetchMore: jest.fn().mockResolvedValue(),
          },
          scannerProfiles: {
            fetchMore: jest.fn().mockResolvedValue(),
          },
        },
        mutate: jest.fn().mockResolvedValue(),
        addSmartQuery: jest.fn(),
      },
    };

    wrapper = mountFn(
      DastProfiles,
      merge(
        {},
        {
          propsData: defaultProps,
          mocks: defaultMocks,
        },
        options,
      ),
    );
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
    profileType          | key                            | givenData                              | expectedValue | exposedAsProp
    ${'siteProfiles'}    | ${'error-message'}             | ${{ errorMessage: 'foo' }}             | ${'foo'}      | ${false}
    ${'siteProfiles'}    | ${'error-details'}             | ${{ errorDetails: ['foo'] }}           | ${'foo'}      | ${false}
    ${'siteProfiles'}    | ${'has-more-profiles-to-load'} | ${{ pageInfo: { hasNextPage: true } }} | ${'true'}     | ${false}
    ${'scannerProfiles'} | ${'error-message'}             | ${{ errorMessage: 'foo' }}             | ${'foo'}      | ${false}
    ${'scannerProfiles'} | ${'error-details'}             | ${{ errorDetails: ['foo'] }}           | ${'foo'}      | ${false}
    ${'scannerProfiles'} | ${'has-more-profiles-to-load'} | ${{ pageInfo: { hasNextPage: true } }} | ${'true'}     | ${false}
  `(
    'passes down $key properly for $profileType',
    async ({ profileType, key, givenData, expectedValue, exposedAsProp }) => {
      const propGetter = exposedAsProp ? 'props' : 'attributes';
      createComponent();
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        profileTypes: { [profileType]: givenData },
      });
      await nextTick();

      expect(getProfilesComponent(profileType)[propGetter](key)).toEqual(expectedValue);
    },
  );

  describe.each`
    description                | profileType
    ${'Site Profiles List'}    | ${'siteProfiles'}
    ${'Scanner Profiles List'} | ${'scannerProfiles'}
  `('$description', ({ profileType }) => {
    beforeEach(() => {
      createComponent();
    });

    it('passes down the loading state when loading is true', () => {
      createComponent({ mocks: { $apollo: { queries: { [profileType]: { loading: true } } } } });

      expect(getProfilesComponent(profileType).attributes('is-loading')).toBe('true');
    });

    it('fetches more results when "@load-more-profiles" is emitted', () => {
      const {
        $apollo: {
          queries: {
            [profileType]: { fetchMore },
          },
        },
      } = wrapper.vm;

      expect(fetchMore).not.toHaveBeenCalled();

      getProfilesComponent(profileType).vm.$emit('load-more-profiles');

      expect(fetchMore).toHaveBeenCalledTimes(1);
    });

    it('deletes profile when "@delete-profile" is emitted', () => {
      const {
        $apollo: { mutate },
      } = wrapper.vm;

      expect(mutate).not.toHaveBeenCalled();

      getProfilesComponent(profileType).vm.$emit('delete-profile');

      expect(mutate).toHaveBeenCalledTimes(1);
    });
  });
});
