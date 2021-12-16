<script>
import { GlAccordion, GlAccordionItem, GlButton, GlLink } from '@gitlab/ui';
import { parseBoolean } from '~/lib/utils/common_utils';
import AccessorUtilities from '~/lib/utils/accessor';
import { BV_COLLAPSE_STATE } from '~/lib/utils/constants';
import { MR_APPROVALS_PROMO_DISMISSED, MR_APPROVALS_PROMO_I18N } from '../../constants';

const canUseLocalStorage = AccessorUtilities.canUseLocalStorage();

export default {
  components: {
    GlAccordion,
    GlAccordionItem,
    GlButton,
    GlLink,
  },
  inject: ['learnMorePath', 'promoImageAlt', 'promoImagePath', 'tryNowPath'],
  data() {
    return {
      userManuallyCollapsed:
        canUseLocalStorage && parseBoolean(localStorage.getItem(MR_APPROVALS_PROMO_DISMISSED)),
    };
  },
  i18n: MR_APPROVALS_PROMO_I18N,
  mounted() {
    if (!this.userManuallyCollapsed) {
      this.$root.$on(BV_COLLAPSE_STATE, this.collapseAccordionItem);
    }
  },
  methods: {
    collapseAccordionItem(_, state) {
      if (state === false) {
        // We only need to track that this happens at least once
        this.$root.$off(BV_COLLAPSE_STATE, this.collapseAccordionItem);

        this.userManuallyCollapsed = true;

        if (canUseLocalStorage) {
          localStorage.setItem(MR_APPROVALS_PROMO_DISMISSED, true);
        }
      }
    },
  },
};
</script>

<template>
  <div class="gl-mt-2">
    <p class="gl-mb-0 gl-text-gray-500">
      {{ $options.i18n.summary }}
    </p>

    <gl-accordion :header-level="3">
      <gl-accordion-item :title="$options.i18n.accordionTitle" :visible="!userManuallyCollapsed">
        <h4 class="gl-font-base gl-line-height-20 gl-mt-5 gl-mb-3">
          {{ $options.i18n.promoTitle }}
        </h4>
        <div class="gl-display-flex">
          <div class="gl-flex-grow-1 gl-max-w-62 gl-mr-5">
            <ul class="gl-list-style-position-inside gl-p-0 gl-mb-3">
              <li v-for="(statement, index) in $options.i18n.valueStatements" :key="index">
                {{ statement }}
              </li>
            </ul>
            <p>
              <gl-link :href="learnMorePath" target="_blank">
                {{ $options.i18n.learnMore }}
              </gl-link>
            </p>
            <gl-button category="primary" variant="confirm" :href="tryNowPath" target="_blank">{{
              $options.i18n.tryNow
            }}</gl-button>
          </div>
          <div class="gl-flex-grow-0 gl-max-w-26 gl-display-none gl-md-display-block">
            <img :src="promoImagePath" :alt="promoImageAlt" class="svg gl-w-full" />
          </div>
        </div>
      </gl-accordion-item>
    </gl-accordion>
  </div>
</template>
