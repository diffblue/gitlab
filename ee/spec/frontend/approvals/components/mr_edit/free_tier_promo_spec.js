import { GlButton, GlLink, GlCollapse } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import {
  MR_APPROVALS_PROMO_I18N,
  MR_APPROVALS_PROMO_TRACKING_EVENTS,
  MR_APPROVALS_PROMO_DISMISSED,
} from 'ee/approvals/constants';
import FreeTierPromo from 'ee/approvals/components/mr_edit/free_tier_promo.vue';

const EXPANDED_ICON = 'chevron-down';
const COLLAPSED_ICON = 'chevron-right';

describe('FreeTierPromo component', () => {
  useLocalStorageSpy();

  let wrapper;
  let trackingSpy;

  const trackingEvents = MR_APPROVALS_PROMO_TRACKING_EVENTS;

  const expectTracking = (category, { action, ...options } = {}) => {
    return expect(trackingSpy).toHaveBeenCalledWith(category, action, options);
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(FreeTierPromo, {
      provide: {
        learnMorePath: '/learn-more',
        promoImageAlt: 'some promo image',
        promoImagePath: '/some-image.svg',
        tryNowPath: '/try-now',
      },
      stubs: {
        LocalStorageSync,
      },
    });
    trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
  };

  const findCollapseToggleButton = () => wrapper.findByTestId('collapse-btn');
  const findCollapse = () => extendedWrapper(wrapper.findComponent(GlCollapse));
  const findLearnMore = () => findCollapse().findComponent(GlLink);
  const findTryNow = () => findCollapse().findComponent(GlButton);

  afterEach(() => {
    unmockTracking();
    localStorage.clear();
  });

  describe('when ready', () => {
    beforeEach(async () => {
      createComponent();
      await nextTick();
    });

    it('shows summary', () => {
      expect(wrapper.findByText(MR_APPROVALS_PROMO_I18N.summary).exists()).toBe(true);
    });

    it('shows collapse toggle button', () => {
      const btn = findCollapseToggleButton();

      expect(btn.text()).toBe(MR_APPROVALS_PROMO_I18N.accordionTitle);
      expect(btn.attributes()).toMatchObject({
        variant: 'link',
        icon: EXPANDED_ICON,
      });
    });

    it('sets up collapse component (visible by default)', () => {
      expect(findCollapse().attributes()).toMatchObject({
        visible: 'true',
      });
    });

    describe('within the collapse', () => {
      it('shows the title', () => {
        const promoTitle = findCollapse().findByRole('heading', {
          name: MR_APPROVALS_PROMO_I18N.promoTitle,
        });

        expect(promoTitle.exists()).toBe(true);
      });

      it('shows promo value statements', () => {
        const statementItemTexts = findCollapse()
          .findAllByRole('listitem')
          .wrappers.map((li) => li.text());

        expect(statementItemTexts).toEqual(MR_APPROVALS_PROMO_I18N.valueStatements);
      });

      it('shows "Learn More" link under collapse', () => {
        const learnMore = findLearnMore();

        expect(learnMore.attributes()).toMatchObject({
          href: '/learn-more',
          target: '_blank',
        });
        expect(learnMore.text()).toBe(MR_APPROVALS_PROMO_I18N.learnMore);
      });

      it('when "Learn More" clicked, tracks', () => {
        findLearnMore().trigger('click');

        expectTracking('_category_', trackingEvents.learnMoreClick);
      });

      it('shows "Try Now" link under collapse', () => {
        const tryNow = findTryNow();

        expect(tryNow.attributes()).toMatchObject({
          category: 'primary',
          variant: 'confirm',
          href: '/try-now',
          target: '_blank',
        });
        expect(tryNow.text()).toBe(MR_APPROVALS_PROMO_I18N.tryNow);
      });

      it('when "Try Now" clicked, tracks', () => {
        findTryNow().trigger('click');

        expectTracking('_category_', trackingEvents.tryNowClick);
      });

      it('shows the promo image', () => {
        const promoImage = findCollapse().findByAltText('some promo image');

        expect(promoImage.attributes('src')).toBe('/some-image.svg');
      });
    });

    describe('when user clicks collapse toggle', () => {
      beforeEach(() => {
        findCollapseToggleButton().vm.$emit('click');
      });

      it('tracks intent to collapse', () => {
        expectTracking(undefined, trackingEvents.collapsePromo);
      });

      it('collapses the collapse component', () => {
        expect(findCollapse().attributes('visible')).toBeUndefined();
      });

      it('updates local storage', () => {
        expect(localStorage.setItem).toHaveBeenCalledWith(MR_APPROVALS_PROMO_DISMISSED, 'true');
      });

      it('updates button icon', () => {
        expect(findCollapseToggleButton().attributes('icon')).toBe(COLLAPSED_ICON);
      });
    });
  });

  describe('when local storage is initialized with mr_approvals_promo.dismissed=true', () => {
    beforeEach(async () => {
      localStorage.setItem(MR_APPROVALS_PROMO_DISMISSED, 'true');
      createComponent();
      await nextTick();
      localStorage.setItem.mockClear();
    });

    it('should show collapse container as collapsed', () => {
      expect(findCollapse().attributes('visible')).toBeUndefined();
    });

    describe('when user clicks collapse toggle', () => {
      beforeEach(() => {
        findCollapseToggleButton().vm.$emit('click');
      });

      it('tracks intent to expand', () => {
        expectTracking(undefined, trackingEvents.expandPromo);
      });

      it('expands the collapse component', () => {
        expect(findCollapse().attributes('visible')).toBe('true');
      });

      it('does NOT update local storage', () => {
        expect(localStorage.setItem).not.toHaveBeenCalled();
      });

      it('updates button icon', () => {
        expect(findCollapseToggleButton().attributes('icon')).toBe(EXPANDED_ICON);
      });
    });
  });
});
