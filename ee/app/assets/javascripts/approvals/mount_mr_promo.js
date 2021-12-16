import Vue from 'vue';
import FreeTierPromo from './components/mr_edit/free_tier_promo.vue';

export default function mountApprovalPromo(el) {
  if (!el) {
    return null;
  }

  const { learnMorePath, promoImageAlt, promoImagePath, tryNowPath } = el.dataset;

  return new Vue({
    el,
    provide: {
      learnMorePath,
      promoImageAlt,
      promoImagePath,
      tryNowPath,
    },
    render(h) {
      return h(FreeTierPromo);
    },
  });
}
