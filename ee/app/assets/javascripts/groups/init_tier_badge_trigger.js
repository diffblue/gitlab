import Vue from 'vue';
import TierBadge from 'ee/vue_shared/components/tier_badge/tier_badge.vue';

export default function initTierBadgeTrigger() {
  const el = document.querySelector('.js-tier-badge-trigger');

  if (!el) {
    return false;
  }

  const { primaryCtaLink, secondaryCtaLink, sourceType } = el.dataset;

  return new Vue({
    el,
    name: 'TierBadgeTriggerRoot',
    components: {
      TierBadge,
    },
    provide: {
      primaryCtaLink,
      secondaryCtaLink,
      sourceType,
    },
    render(createElement) {
      return createElement(TierBadge);
    },
  });
}
