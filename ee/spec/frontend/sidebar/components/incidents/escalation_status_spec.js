import { shallowMount } from '@vue/test-utils';
import EscalationStatus from 'ee/sidebar/components/incidents/escalation_status.vue';
import InnerEscalationStatus from '~/sidebar/components/incidents/escalation_status.vue';
import { STATUS_TRIGGERED } from '~/sidebar/constants';
import { i18nStatusHeaderText, STATUS_SUBTEXTS } from 'ee/sidebar/constants';

describe('EscalationStatus', () => {
  let wrapper;

  function createComponent(glFeatures = {}) {
    wrapper = shallowMount(EscalationStatus, {
      propsData: {
        status: STATUS_TRIGGERED,
      },
      provide: {
        glFeatures: {
          escalationPolicies: true,
          ...glFeatures,
        },
      },
    });
  }

  const findInnerStatusComponent = () => wrapper.findComponent(InnerEscalationStatus);

  describe('when licensed features enabled', () => {
    beforeEach(() => {
      createComponent();
    });

    it('provides the dropdown header', () => {
      expect(findInnerStatusComponent().props('headerText')).toBe(i18nStatusHeaderText);
    });

    it('provides the status subtexts', () => {
      expect(findInnerStatusComponent().props('statusSubtexts')).toBe(STATUS_SUBTEXTS);
    });
  });

  describe('when licensed features disabled', () => {
    beforeEach(() => {
      createComponent({ escalationPolicies: false });
    });

    it("doesn't provide the dropdown header", () => {
      expect(findInnerStatusComponent().props('headerText')).toBe('');
    });

    it("doesn't provide the status subtexts", () => {
      expect(findInnerStatusComponent().props('statusSubtexts')).toEqual({});
    });
  });
});
