import { mountExtended } from 'helpers/vue_test_utils_helper';
import { SCANNER_TYPE, SITE_TYPE } from 'ee/on_demand_scans/constants';
import DastProfilesDrawerHeader from 'ee/security_configuration/dast_profiles/dast_profiles_drawer/dast_profiles_drawer_header.vue';

import { scannerProfiles } from 'ee_jest/security_configuration/dast_profiles/mocks/mock_data';

describe('DastProfilesDrawerForm', () => {
  let wrapper;
  const profile = scannerProfiles[0];

  const createComponent = (options = {}) => {
    wrapper = mountExtended(DastProfilesDrawerHeader, {
      propsData: {
        ...options,
      },
    });
  };

  const findDrawerHeader = () => wrapper.findByTestId('drawer-header');
  const findNewScanButton = () => wrapper.findByTestId('new-profile-button');

  describe.each`
    profileItem | profileType     | isEditingMode | expectedResult
    ${{}}       | ${SCANNER_TYPE} | ${true}       | ${'New scanner profile'}
    ${{}}       | ${SITE_TYPE}    | ${true}       | ${'New site profile'}
    ${profile}  | ${SCANNER_TYPE} | ${true}       | ${'Edit scanner profile'}
    ${profile}  | ${SITE_TYPE}    | ${true}       | ${'Edit site profile'}
    ${{}}       | ${SCANNER_TYPE} | ${false}      | ${'Scanner profile library'}
    ${{}}       | ${SITE_TYPE}    | ${false}      | ${'Site profile library'}
  `('header type', ({ profileItem, profileType, isEditingMode, expectedResult }) => {
    beforeEach(() => {
      createComponent({ profile: profileItem, profileType, isEditingMode });
    });

    it('should render correct header based on mode', () => {
      expect(findDrawerHeader().text()).toContain(expectedResult);
    });
  });

  describe.each`
    profileItem | profileType     | showNewProfileButton | showButton
    ${{}}       | ${SCANNER_TYPE} | ${true}              | ${true}
    ${{}}       | ${SITE_TYPE}    | ${true}              | ${true}
    ${profile}  | ${SCANNER_TYPE} | ${false}             | ${false}
    ${profile}  | ${SITE_TYPE}    | ${false}             | ${false}
  `('new profile button', ({ profileItem, profileType, showNewProfileButton, showButton }) => {
    beforeEach(() => {
      createComponent({ profile: profileItem, profileType, showNewProfileButton });
    });

    it('should hide new profile button', () => {
      expect(findNewScanButton().exists()).toBe(showButton);
    });
  });
});
