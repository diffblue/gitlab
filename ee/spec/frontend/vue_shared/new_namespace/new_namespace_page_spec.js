import { GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import WelcomePage from '~/vue_shared/new_namespace/components/welcome.vue';
import NewNamespacePage from '~/vue_shared/new_namespace/new_namespace_page.vue';
import VerificationPage from 'ee_component/pages/groups/new/components/credit_card_verification.vue';
import Zuora from 'ee/billings/components/zuora.vue';

describe('Experimental new project creation app', () => {
  let wrapper;

  const findWelcomePage = () => wrapper.findComponent(WelcomePage);
  const findVerificationPage = () => wrapper.findComponent(VerificationPage);
  const findZuora = () => wrapper.findComponent(Zuora);

  const DEFAULT_PROPS = {
    title: 'Create something',
    initialBreadcrumb: 'Something',
    panels: [
      { name: 'panel1', selector: '#some-selector1' },
      { name: 'panel2', selector: '#some-selector2' },
    ],
    persistenceKey: 'DEMO-PERSISTENCE-KEY',
  };

  const DEFAULT_PROVIDES = {
    verificationFormUrl: 'https://gitlab.com',
    subscriptionsUrl: 'https://gitlab.com',
  };

  const createComponent = ({ provide = {} } = {}) => {
    wrapper = mount(NewNamespacePage, {
      propsData: DEFAULT_PROPS,
      provide: { ...DEFAULT_PROVIDES, ...provide },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('does not show verification page', () => {
    createComponent();
    expect(findVerificationPage().exists()).toBe(false);
  });

  describe('when verificationRequired true', () => {
    beforeEach(() => {
      createComponent({ provide: { verificationRequired: true } });
    });

    it('does not show welcome page', () => {
      expect(findWelcomePage().exists()).toBe(false);
    });

    it('shows verification page', () => {
      expect(findVerificationPage().exists()).toBe(true);
    });

    describe('when verificationCompleted becomes true', () => {
      beforeEach(() => {
        findVerificationPage().vm.$refs.zuora = {
          submit: jest.fn(() => {
            findZuora().vm.$emit('success');
          }),
        };
        wrapper.findComponent(GlButton).vm.$emit('click');
      });

      it('shows welcome page', () => {
        expect(findWelcomePage().exists()).toBe(true);
      });

      it('does not show verification page', () => {
        expect(findVerificationPage().exists()).toBe(false);
      });
    });
  });
});
