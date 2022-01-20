<script>
import BuyAddonsApp from 'ee/subscriptions/buy_addons_shared/components/app.vue';
import {
  CI_MINUTES_PER_PACK,
  planTags,
  I18N_CI_MINUTES_PRICE_PER_UNIT,
  I18N_CI_MINUTES_PRODUCT_LABEL,
  I18N_CI_MINUTES_PRODUCT_UNIT,
  I18N_DETAILS_FORMULA,
  I18N_DETAILS_FORMULA_WITH_ALERT,
  I18N_CI_MINUTES_FORMULA_TOTAL,
  i18nCIMinutesSummaryTitle,
  I18N_CI_MINUTES_SUMMARY_TOTAL,
  I18N_CI_MINUTES_ALERT_TEXT,
  I18N_CI_MINUTES_TITLE,
} from 'ee/subscriptions/buy_addons_shared/constants';

export default {
  components: {
    BuyAddonsApp,
  },
  computed: {
    tags() {
      return [planTags.CI_1000_MINUTES_PLAN];
    },
    config() {
      // These will move into the GraphQL store. See: https://gitlab.com/gitlab-org/gitlab/-/issues/346620
      return {
        alertText: I18N_CI_MINUTES_ALERT_TEXT,
        formula: I18N_DETAILS_FORMULA,
        formulaWithAlert: I18N_DETAILS_FORMULA_WITH_ALERT,
        formulaTotal: I18N_CI_MINUTES_FORMULA_TOTAL,
        hasExpiration: false,
        pricePerUnit: I18N_CI_MINUTES_PRICE_PER_UNIT,
        productLabel: I18N_CI_MINUTES_PRODUCT_LABEL,
        productUnit: I18N_CI_MINUTES_PRODUCT_UNIT,
        quantityPerPack: CI_MINUTES_PER_PACK,
        summaryTitle: i18nCIMinutesSummaryTitle,
        summaryTotal: I18N_CI_MINUTES_SUMMARY_TOTAL,
        title: I18N_CI_MINUTES_TITLE,
      };
    },
  },
};
</script>
<template>
  <buy-addons-app :config="config" :tags="tags" />
</template>
