import { GlAccordionItem, GlButton, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { BV_COLLAPSE_STATE } from '~/lib/utils/constants';

import { MR_APPROVALS_PROMO_I18N } from 'ee/approvals/constants';
import FreeTierPromo from 'ee/approvals/components/mr_edit/free_tier_promo.vue';

describe('PaidFeatureCalloutBadge component', () => {
  let wrapper;

  const createComponent = (providers = {}) => {
    return shallowMountExtended(FreeTierPromo, {
      provide: {
        learnMorePath: '/learn-more',
        promoImageAlt: 'some promo image',
        promoImagePath: '/some-image.svg',
        tryNowPath: '/try-now',
        ...providers,
      },
    });
  };

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('summary text', () => {
    it('is rendered correctly', () => {
      expect(wrapper.findByText(MR_APPROVALS_PROMO_I18N.summary).exists()).toBeTruthy();
    });
  });

  describe('promo gl-accordion item', () => {
    let promoItem;

    beforeEach(() => {
      promoItem = wrapper.findComponent(GlAccordionItem);
    });

    it('is given the expected title prop', () => {
      expect(promoItem.props('title')).toBe(MR_APPROVALS_PROMO_I18N.accordionTitle);
    });

    it('starts expanded by default', () => {
      expect(promoItem.props('visible')).toBeTruthy();
    });
  });

  describe('promo title', () => {
    it('is rendered correctly', () => {
      const promoTitle = wrapper.findByRole('heading', {
        name: MR_APPROVALS_PROMO_I18N.promoTitle,
      });

      expect(promoTitle.exists()).toBeTruthy();
    });
  });

  describe('promo value statements list', () => {
    it('contains the expected statements', () => {
      const statementItemTexts = wrapper.findAllByRole('listitem').wrappers.map((li) => li.text());

      expect(statementItemTexts).toEqual(MR_APPROVALS_PROMO_I18N.valueStatements);
    });
  });

  describe('"Learn More" link', () => {
    let learnMoreLink;

    beforeEach(() => {
      learnMoreLink = wrapper.findComponent(GlLink);
    });

    it('has correct href', () => {
      expect(learnMoreLink.attributes('href')).toBe('/learn-more');
    });

    it('has correct text', () => {
      expect(learnMoreLink.text()).toBe(MR_APPROVALS_PROMO_I18N.learnMore);
    });
  });

  describe('"Try Now" button', () => {
    let tryNowBtn;

    beforeEach(() => {
      tryNowBtn = wrapper.findComponent(GlButton);
    });

    it('has correct href', () => {
      expect(tryNowBtn.attributes('href')).toBe('/try-now');
    });

    it('has correct text', () => {
      expect(tryNowBtn.text()).toBe(MR_APPROVALS_PROMO_I18N.tryNow);
    });
  });

  describe('promo image', () => {
    it('has correct src', () => {
      const promoImage = wrapper.findByAltText('some promo image');

      expect(promoImage.attributes('src')).toBe('/some-image.svg');
    });
  });

  describe('user interactions', () => {
    describe('when user does not interact with the promo', () => {
      describe('and we render a second time', () => {
        it('also starts expanded by default', () => {
          const secondWrapper = createComponent();
          const promoItem = secondWrapper.findComponent(GlAccordionItem);

          expect(promoItem.props('visible')).toBeTruthy();
        });
      });
    });

    describe('when user collapses the promo', () => {
      beforeEach(async () => {
        await wrapper.vm.$root.$emit(BV_COLLAPSE_STATE, 'accordion-item-id', false);
      });

      afterEach(() => {
        localStorage.clear();
      });

      it('reflects that state in the promo collapsible item', () => {
        const promoItem = wrapper.findComponent(GlAccordionItem);

        expect(promoItem.props('visible')).toBeFalsy();
      });

      describe('and we render a second time', () => {
        it('starts collapsed by default', () => {
          const secondWrapper = createComponent();
          const promoItem = secondWrapper.findComponent(GlAccordionItem);

          expect(promoItem.props('visible')).toBeFalsy();
        });
      });
    });
  });
});
