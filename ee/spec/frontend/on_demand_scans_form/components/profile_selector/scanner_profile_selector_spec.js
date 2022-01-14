import { shallowMount } from '@vue/test-utils';
import { merge } from 'lodash';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ProfileSelector from 'ee/on_demand_scans_form/components/profile_selector/profile_selector.vue';
import OnDemandScansScannerProfileSelector from 'ee/on_demand_scans_form/components/profile_selector/scanner_profile_selector.vue';
import ScannerProfileSummary from 'ee/on_demand_scans_form/components/profile_selector/scanner_profile_summary.vue';
import { scannerProfiles } from 'ee_jest/security_configuration/dast_profiles/mocks/mock_data';

const TEST_LIBRARY_PATH = '/test/scanner/profiles/library/path';
const TEST_NEW_PATH = '/test/new/scanner/profile/path';
const TEST_ATTRS = {
  'data-foo': 'bar',
};
const profiles = scannerProfiles.map((x) => {
  return { ...x, dropdownLabel: x.profileName };
});

describe('OnDemandScansScannerProfileSelector', () => {
  let wrapper;

  const wrapperFactory = (mountFn = shallowMount) => (options = {}) => {
    wrapper = mountFn(
      OnDemandScansScannerProfileSelector,
      merge(
        {
          propsData: {
            profiles: [],
          },
          attrs: TEST_ATTRS,
          provide: {
            scannerProfilesLibraryPath: TEST_LIBRARY_PATH,
            newScannerProfilePath: TEST_NEW_PATH,
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
  const createFullComponent = wrapperFactory(mountExtended);

  const findProfileSelector = () => wrapper.findComponent(ProfileSelector);
  const findSelectorOptions = () => wrapper.findAll('li');
  const findProfileSummary = () => wrapper.findByTestId('selected-profile-summary');

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders properly with profiles', () => {
    const [selectedProfile] = profiles;
    createFullComponent({
      propsData: { profiles, value: profiles[0].id },
    });

    expect(findProfileSummary().html()).toContain(selectedProfile.editPath);
    profiles.forEach((profile, index) => {
      expect(findSelectorOptions().at(index).text()).toContain(profile.profileName);
    });
  });

  it('renders properly without profiles', () => {
    createFullComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('render summary component ', () => {
    const selectedProfile = profiles[0];

    createComponent({
      propsData: { profiles, value: selectedProfile.id, selectedProfile },
    });

    expect(wrapper.findComponent(ScannerProfileSummary).exists()).toBe(true);
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
        dastScanId: null,
        libraryPath: TEST_LIBRARY_PATH,
        newProfilePath: TEST_NEW_PATH,
        profiles,
        value: null,
      });
      expect(sel.attributes()).toMatchObject(TEST_ATTRS);
    });
  });
});
