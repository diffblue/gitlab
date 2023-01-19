import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { SCANNER_TYPE, SITE_TYPE } from 'ee/on_demand_scans/constants';
import DastProfilesDrawerList from 'ee/security_configuration/dast_profiles/dast_profiles_drawer/dast_profiles_drawer_list.vue';
import ScannerProfileSummary from 'ee/security_configuration/dast_profiles/dast_profile_selector/scanner_profile_summary.vue';
import SiteProfileSummary from 'ee/security_configuration/dast_profiles/dast_profile_selector/site_profile_summary.vue';
import {
  scannerProfiles,
  siteProfiles,
} from 'ee_jest/security_configuration/dast_profiles/mocks/mock_data';

describe('DastProfilesDrawerList', () => {
  let wrapper;

  const createComponent = (options = {}) => {
    wrapper = mountExtended(DastProfilesDrawerList, {
      propsData: {
        ...options,
      },
      provide: {
        projectPath: 'group/project',
      },
    });
  };

  const findEditButton = () => wrapper.findByTestId('profile-edit-btn');
  const findSelectButton = () => wrapper.findByTestId('profile-select-btn');
  const findAllScannerProfileSummary = () => wrapper.findAllComponents(ScannerProfileSummary);
  const findScannerProfileSummary = () => wrapper.findComponent(ScannerProfileSummary);
  const findAllSiteProfileSummary = () => wrapper.findAllComponents(SiteProfileSummary);
  const findSiteProfileSummary = () => wrapper.findComponent(SiteProfileSummary);

  it('should render scanner profile summary based on profile type', () => {
    createComponent({ profiles: scannerProfiles, profileType: SCANNER_TYPE });

    expect(findScannerProfileSummary().exists()).toBe(true);
    expect(findAllScannerProfileSummary()).toHaveLength(scannerProfiles.length);
  });

  it('should render site profile summary based on profile type', () => {
    createComponent({ profiles: siteProfiles, profileType: SITE_TYPE });

    expect(findSiteProfileSummary().exists()).toBe(true);
    expect(findAllSiteProfileSummary()).toHaveLength(siteProfiles.length);
  });

  it('should emit edit event', async () => {
    createComponent({ profiles: scannerProfiles });

    findEditButton().vm.$emit('click');

    await nextTick();

    expect(wrapper.emitted('edit')).toHaveLength(1);
    expect(wrapper.emitted('edit')[0]).toEqual([scannerProfiles[0]]);
  });

  it('should emit select event', async () => {
    createComponent({ profiles: scannerProfiles });

    findSelectButton().vm.$emit('click');

    await nextTick();

    expect(wrapper.emitted('select-profile')).toHaveLength(1);
    expect(wrapper.emitted('select-profile')[0]).toEqual([
      { profile: scannerProfiles[0], profileType: SCANNER_TYPE },
    ]);
  });
});
