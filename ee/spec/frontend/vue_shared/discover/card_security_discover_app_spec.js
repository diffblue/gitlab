import { shallowMount } from '@vue/test-utils';
import CardSecurityDiscoverApp from 'ee/vue_shared/discover/card_security_discover_app.vue';
import { mockTracking } from 'helpers/tracking_helper';

describe('Card security discover app', () => {
  let wrapper;

  const createComponent = (propsData) => {
    wrapper = shallowMount(CardSecurityDiscoverApp, {
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Project discover carousel', () => {
    beforeEach(() => {
      const propsData = {
        project: {
          id: 1,
          name: 'Awesome Project',
        },
        linkMain: '/link/main',
        linkSecondary: '/link/secondary',
        linkFeedback: 'link/feedback',
      };
      createComponent(propsData);
    });

    it('renders component properly', () => {
      expect(wrapper.find(CardSecurityDiscoverApp).exists()).toBe(true);
    });

    it('renders discover title properly', () => {
      expect(wrapper.find('.discover-title').html()).toContain(
        'Security capabilities, integrated into your development lifecycle',
      );
    });

    it('renders discover feedback link properly', () => {
      expect(wrapper.find('.discover-button-feedback').html()).toContain('Send feedback');
    });

    it('renders discover upgrade links properly', () => {
      expect(wrapper.find('.discover-button-upgrade').html()).toContain('Upgrade now');
    });

    it('renders discover trial links properly', () => {
      expect(wrapper.find('.discover-button-trial').html()).toContain('Start a free trial');
    });

    describe('Tracking', () => {
      let spy;

      beforeEach(() => {
        spy = mockTracking('_category_', wrapper.element, jest.spyOn);
      });

      it('tracks an event when clicked on upgrade', () => {
        wrapper.find('.discover-button-upgrade').trigger('click');

        expect(spy).toHaveBeenCalledWith('_category_', 'click_button', {
          label: 'security-discover-upgrade-cta',
          property: '0',
        });
      });

      it('tracks an event when clicked on trial', () => {
        wrapper.find('.discover-button-trial').trigger('click');

        expect(spy).toHaveBeenCalledWith('_category_', 'click_button', {
          label: 'security-discover-trial-cta',
          property: '0',
        });
      });

      it('tracks an event when clicked on a slider', () => {
        const expectedCategory = undefined;

        document.body.dataset.page = '_category_';
        wrapper.vm.onSlideStart(1);

        expect(spy).toHaveBeenCalledWith(expectedCategory, 'click_button', {
          label: 'security-discover-carousel',
          property: 'sliding0-1',
        });
      });

      it('tracks an event when clicked on feedback', () => {
        wrapper.find('.discover-button-feedback').trigger('click');

        expect(spy).toHaveBeenCalledWith('_category_', 'click_button', {
          label: 'security-discover-feedback-cta',
          property: '0',
        });
      });
    });
  });
});
