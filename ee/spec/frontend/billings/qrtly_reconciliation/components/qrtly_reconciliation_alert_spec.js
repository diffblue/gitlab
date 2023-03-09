import { GlAlert, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Cookie from '~/lib/utils/cookies';
import QrtlyReconciliationAlert from 'ee/billings/qrtly_reconciliation/components/qrtly_reconciliation_alert.vue';
import { i18n } from 'ee/billings/qrtly_reconciliation/constants';

jest.mock('~/lib/utils/cookies', () => ({
  set: jest.fn(),
}));

describe('Qrtly Reconciliation Alert', () => {
  let wrapper;
  const reconciliationDate = new Date('2020-07-10');

  const createComponent = (props = {}) => {
    return shallowMount(QrtlyReconciliationAlert, {
      propsData: {
        cookieKey: 'key',
        date: reconciliationDate,
        ...props,
      },
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);

  describe('Rendering', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('renders alert title with date', () => {
      expect(findAlert().attributes('title')).toContain(`occur on 2020-07-10`);
    });

    it('has the correct link to the help page', () => {
      expect(findAlert().attributes('primarybuttonlink')).toBe(
        '/help/subscriptions/quarterly_reconciliation',
      );
    });

    it('has the correct link to contact support', () => {
      expect(findAlert().attributes('secondarybuttonlink')).toBe(i18n.buttons.secondary.link);
    });

    it('has the correct description for EE', () => {
      expect(wrapper.findComponent(GlSprintf).attributes('message')).toContain(i18n.description.ee);
    });

    describe('when gitlab.com', () => {
      beforeEach(() => {
        wrapper = createComponent({ usesNamespacePlan: true });
      });

      it('has the correct description', () => {
        expect(wrapper.findComponent(GlSprintf).attributes('message')).toContain(
          i18n.description.usesNamespacePlan,
        );
      });
    });
  });

  describe('methods', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('sets the cookie on dismis', () => {
      findAlert().vm.$emit('dismiss');

      expect(Cookie.set).toHaveBeenCalledTimes(1);
      expect(Cookie.set).toHaveBeenCalledWith('key', true, { expires: 4 });
    });
  });
});
