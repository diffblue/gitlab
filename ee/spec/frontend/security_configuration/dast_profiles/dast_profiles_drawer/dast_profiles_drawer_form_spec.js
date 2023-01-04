import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { SCANNER_TYPE, SITE_TYPE } from 'ee/on_demand_scans/constants';
import DastProfilesDrawerForm from 'ee/security_configuration/dast_profiles/dast_profiles_drawer/dast_profiles_drawer_form.vue';
import DastScannerProfileForm from 'ee/security_configuration/dast_profiles/dast_scanner_profiles/components/dast_scanner_profile_form.vue';
import DastSiteProfileForm from 'ee/security_configuration/dast_profiles/dast_site_profiles/components/dast_site_profile_form.vue';
import { scannerProfiles } from 'ee_jest/security_configuration/dast_profiles/mocks/mock_data';

describe('DastProfilesDrawerForm', () => {
  let wrapper;
  const projectPath = 'projectPath';
  const profile = scannerProfiles[0];

  const createComponent = (options = {}, listeners = {}) => {
    wrapper = mountExtended(DastProfilesDrawerForm, {
      propsData: {
        ...options,
      },
      provide: {
        projectPath,
      },
      listeners,
    });
  };

  const findCancelButton = () => wrapper.findByTestId('dast-profile-form-cancel-button');
  const findDastScannerProfileForm = () => wrapper.findComponent(DastScannerProfileForm);
  const findDastSiteProfileForm = () => wrapper.findComponent(DastSiteProfileForm);

  it('should render scanner profile form based on profile type', () => {
    createComponent({ profile, profileType: SCANNER_TYPE });

    expect(findDastScannerProfileForm().exists()).toBe(true);
  });

  it('should render site profile form based on profile type', () => {
    createComponent({ profile, profileType: SITE_TYPE });

    expect(findDastSiteProfileForm().exists()).toBe(true);
  });

  it('should emit cancel event when cancelled', async () => {
    const onCancel = jest.fn();
    createComponent({ profile, profileType: SCANNER_TYPE }, { cancel: onCancel });

    findCancelButton().trigger('click');
    await nextTick();

    expect(onCancel).toHaveBeenCalled();
  });
});
