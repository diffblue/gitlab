import { shallowMount } from '@vue/test-utils';
import { makeMockUserCalloutDismisser } from 'helpers/mock_user_callout_dismisser';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import SecurityTrainingPromo from 'ee/vue_shared/security_reports/components/security_training_promo.vue';
import {
  TRACK_PROMOTION_BANNER_CTA_CLICK_ACTION,
  TRACK_PROMOTION_BANNER_CTA_CLICK_LABEL,
} from '~/security_configuration/constants';

const SECURITY_CONFIGURATION_PATH = 'foo/bar';
const PROJECT_FULL_PATH = 'namespace/project';

describe('Security training promo component', () => {
  let wrapper;
  const userCalloutDismissSpy = jest.fn();
  const defaultScopedSlotSpy = jest.fn();

  const createComponent = ({
    shouldShowCallout = true,
    defaultScopedSlot = defaultScopedSlotSpy,
  } = {}) => {
    wrapper = shallowMount(SecurityTrainingPromo, {
      propsData: {
        projectFullPath: PROJECT_FULL_PATH,
        securityConfigurationPath: SECURITY_CONFIGURATION_PATH,
      },
      scopedSlots: {
        default: defaultScopedSlot,
      },
      stubs: {
        UserCalloutDismisser: makeMockUserCalloutDismisser({
          dismiss: userCalloutDismissSpy,
          shouldShowCallout,
        }),
      },
    });
  };

  const callDismissSlotProp = () => defaultScopedSlotSpy.mock.calls[0][0].dismiss();
  const callTrackCTAClickSlotProp = () => defaultScopedSlotSpy.mock.calls[0][0].trackCTAClick();

  describe('slot', () => {
    it('passes expected slot props to child', () => {
      createComponent();

      expect(defaultScopedSlotSpy).toHaveBeenLastCalledWith({
        buttonLink: `${SECURITY_CONFIGURATION_PATH}?tab=vulnerability-management`,
        buttonText: SecurityTrainingPromo.i18n.buttonText,
        dismiss: expect.any(Function),
        trackCTAClick: expect.any(Function),
      });
    });

    it('should render the slot content', () => {
      const defaultScopedSlot = '<div>some slot content</div>';

      createComponent({ defaultScopedSlot });
      expect(wrapper.html()).toBe(defaultScopedSlot);
    });
  });

  describe('dismissal', () => {
    it('should dismiss the callout when the banner is closed', () => {
      createComponent();

      expect(userCalloutDismissSpy).not.toHaveBeenCalled();
      callDismissSlotProp();
      expect(userCalloutDismissSpy).toHaveBeenCalled();
    });

    it('should not render the slot content once it has been dismissed', () => {
      const defaultScopedSlot = '<div>some slot content</div>';

      createComponent({ shouldShowCallout: false, defaultScopedSlot });
      expect(wrapper.html()).toBe('');
    });
  });

  describe('metrics', () => {
    let trackingSpy;

    beforeEach(() => {
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      createComponent();
    });

    afterEach(() => {
      unmockTracking();
    });

    it('tracks clicks on the CTA button', () => {
      expect(trackingSpy).not.toHaveBeenCalled();

      callTrackCTAClickSlotProp();

      expect(trackingSpy).toHaveBeenCalledWith(undefined, TRACK_PROMOTION_BANNER_CTA_CLICK_ACTION, {
        label: TRACK_PROMOTION_BANNER_CTA_CLICK_LABEL,
        property: PROJECT_FULL_PATH,
      });
    });
  });
});
