import { mount, shallowMount } from '@vue/test-utils';
import { merge } from 'lodash';
import ProfileSelector from 'ee/on_demand_scans_form/components/profile_selector/profile_selector.vue';
import OnDemandScansSiteProfileSelector from 'ee/on_demand_scans_form/components/profile_selector/site_profile_selector.vue';
import SiteProfileSummary from 'ee/on_demand_scans_form/components/profile_selector/site_profile_summary.vue';
import { siteProfiles } from '../../mocks/mock_data';

const TEST_LIBRARY_PATH = '/test/site/profiles/library/path';
const TEST_NEW_PATH = '/test/new/site/profile/path';
const TEST_ATTRS = {
  'data-foo': 'bar',
};
const profiles = siteProfiles.map((x) => {
  return {
    ...x,
    dropdownLabel: `${x.profileName}: ${x.targetUrl}`,
  };
});

describe('OnDemandScansSiteProfileSelector', () => {
  let wrapper;

  const wrapperFactory = (mountFn = shallowMount) => (options = {}) => {
    wrapper = mountFn(
      OnDemandScansSiteProfileSelector,
      merge(
        {
          propsData: {
            profiles: [],
          },
          attrs: TEST_ATTRS,
          provide: {
            siteProfilesLibraryPath: TEST_LIBRARY_PATH,
            newSiteProfilePath: TEST_NEW_PATH,
          },
          slots: {
            summary: `<div>${profiles[0].profileName}'s summary</div>`,
          },
        },
        options,
      ),
    );
  };
  const createComponent = wrapperFactory();
  const createFullComponent = wrapperFactory(mount);

  const findProfileSelector = () => wrapper.find(ProfileSelector);

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders properly with profiles', () => {
    createFullComponent({
      propsData: { profiles, value: profiles[0].id },
    });

    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders properly without profiles', () => {
    createFullComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  describe('profile summary', () => {
    it('is rendered when a profile is selected', () => {
      const selectedProfile = profiles[0];

      createComponent({
        propsData: { profiles, value: selectedProfile.id, selectedProfile },
      });

      expect(wrapper.findComponent(SiteProfileSummary).exists()).toBe(true);
    });

    it('is not rendered when no profile is selected', () => {
      createComponent({
        propsData: { profiles, selectedProfile: null },
      });

      expect(wrapper.findComponent(SiteProfileSummary).exists()).toBe(false);
    });
  });

  it('sets listeners on profile selector component', () => {
    const inputHandler = jest.fn();
    createComponent({
      listeners: {
        input: inputHandler,
      },
    });
    findProfileSelector().vm.$emit('input');

    expect(inputHandler).toHaveBeenCalled();
  });

  describe('with profiles', () => {
    it('renders profile selector', () => {
      createComponent({
        propsData: { profiles },
      });
      const sel = findProfileSelector();

      expect(sel.props()).toEqual({
        libraryPath: TEST_LIBRARY_PATH,
        newProfilePath: TEST_NEW_PATH,
        profiles,
        value: null,
      });
      expect(sel.attributes()).toMatchObject(TEST_ATTRS);
    });
  });
});
