import { GlAccordionItem, GlButton, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { __, s__ } from '~/locale';

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
      expect(wrapper.findByText(__('Approvals are optional.')).exists()).toBeTruthy();
    });
  });

  describe('promo gl-accordion item', () => {
    let promoItem;

    beforeEach(() => {
      promoItem = wrapper.findComponent(GlAccordionItem);
    });

    it('is given the expected title prop', () => {
      expect(promoItem.props('title')).toBe(s__('ApprovalRule|Approval rules'));
    });

    it('starts expanded by default', () => {
      expect(promoItem.props('visible')).toBeTruthy();
    });
  });

  describe('promo title', () => {
    it('is rendered correctly', () => {
      const promoTitle = wrapper.findByRole('heading', {
        name: s__('ApprovalRule|Add required approvers to improve your code review process'),
      });

      expect(promoTitle.exists()).toBeTruthy();
    });
  });

  describe('promo value statements list', () => {
    it('contains the expected statements', () => {
      const statementItemTexts = wrapper.findAllByRole('listitem').wrappers.map((li) => li.text());

      expect(statementItemTexts).toEqual([
        s__('ApprovalRule|Assign approvers by area of expertise.'),
        s__('ApprovalRule|Increase your organization’s code quality.'),
        s__('ApprovalRule|Reduce the overall time to merge.'),
        s__('ApprovalRule|Let GitLab designate eligible approvers based on the files changed.'),
      ]);
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
      expect(learnMoreLink.text()).toBe(
        s__('ApprovalRule|Learn more about merge request approval.'),
      );
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
      expect(tryNowBtn.text()).toBe(s__('ApprovalRule|Try it for free'));
    });
  });

  describe('promo image', () => {
    it('has correct src', () => {
      const promoImage = wrapper.findByAltText('some promo image');

      expect(promoImage.attributes('src')).toBe('/some-image.svg');
    });
  });
});
