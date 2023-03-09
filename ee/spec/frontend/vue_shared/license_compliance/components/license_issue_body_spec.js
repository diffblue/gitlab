import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { LICENSE_LINK_TELEMETRY_EVENT } from 'ee/vue_shared/license_compliance/constants';
import api from '~/api';
import LicenseIssueBody from 'ee/vue_shared/license_compliance/components/license_issue_body.vue';
import LicensePackages from 'ee/vue_shared/license_compliance/components/license_packages.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { licenseReport } from '../mock_data';

describe('LicenseIssueBody', () => {
  let wrapper;

  const findLicenseIssueBody = () => wrapper.findComponent(LicenseIssueBody);
  const findLicensePackages = () => wrapper.findComponent(LicensePackages);
  const findGlLink = () => wrapper.findComponent(GlLink);
  const findText = () => wrapper.find('[data-testid="license-copy"]');

  const createComponent = (props = {}) => {
    wrapper = extendedWrapper(
      shallowMount(LicenseIssueBody, {
        propsData: {
          ...props,
        },
      }),
    );
  };

  beforeEach(() => {
    createComponent({ issue: licenseReport[0] });
  });

  describe('on load', () => {
    it('renders license issue body', () => {
      expect(findLicenseIssueBody().exists()).toBe(true);
    });

    it('renders packages list', () => {
      expect(findLicensePackages().exists()).toBe(true);
    });
  });

  describe('when issue url is defined', () => {
    it('renders link to view license', () => {
      const link = findGlLink();
      const text = findText();

      expect(link.text()).toBe(licenseReport[0].name);
      expect(link.attributes('href')).toBe(licenseReport[0].url);
      expect(text.exists()).toBe(false);
    });
  });

  describe('when issue url is undefined', () => {
    beforeEach(() => {
      createComponent({ issue: licenseReport[1] });
    });

    it('renders text to view license', () => {
      const link = findGlLink();
      const text = findText();

      expect(text.text()).toBe(licenseReport[1].name);
      expect(link.exists()).toBe(false);
    });
  });

  describe('template without packages', () => {
    beforeEach(() => {
      const issueWithoutPackages = licenseReport[0];
      issueWithoutPackages.packages = [];

      createComponent({ issue: issueWithoutPackages });
    });

    it('does not render packages list', () => {
      const packages = findLicensePackages();
      expect(packages.exists()).toBe(false);
    });
  });

  describe('event tracking', () => {
    let trackUserEventSpy;
    let trackCounterEventSpy;

    beforeEach(() => {
      trackUserEventSpy = jest.spyOn(api, 'trackRedisHllUserEvent').mockImplementation(() => {});
      trackCounterEventSpy = jest.spyOn(api, 'trackRedisCounterEvent').mockImplementation(() => {});
    });

    afterEach(() => {
      trackUserEventSpy.mockRestore();
      trackCounterEventSpy.mockRestore();
    });

    it('tracks users_visiting_testing_license_compliance_full_report', () => {
      findGlLink().vm.$emit('click');

      expect(trackUserEventSpy).toHaveBeenCalledWith(LICENSE_LINK_TELEMETRY_EVENT);
      expect(trackCounterEventSpy).toHaveBeenCalledWith(LICENSE_LINK_TELEMETRY_EVENT);
    });
  });
});
