<script>
import BuyAddonsApp from 'ee/subscriptions/buy_addons_shared/components/app.vue';
import {
  I18N_STORAGE_PRODUCT_LABEL,
  I18N_STORAGE_PRODUCT_UNIT,
  I18N_DETAILS_FORMULA,
  I18N_STORAGE_FORMULA_TOTAL,
  I18N_DETAILS_FORMULA_WITH_ALERT,
  i18nStorageSummaryTitle,
  I18N_STORAGE_SUMMARY_TOTAL,
  I18N_STORAGE_TITLE,
  I18N_STORAGE_PRICE_PER_UNIT,
  planTags,
  STORAGE_PER_PACK,
} from 'ee/subscriptions/buy_addons_shared/constants';

export default {
  name: 'BuyStorageApp',
  components: {
    BuyAddonsApp,
  },
  computed: {
    tags() {
      return [planTags.STORAGE_PLAN];
    },
    config() {
      // These will move into the GraphQL store. See: https://gitlab.com/gitlab-org/gitlab/-/issues/346620
      return {
        alertText: '',
        formula: I18N_DETAILS_FORMULA,
        formulaWithAlert: I18N_DETAILS_FORMULA_WITH_ALERT,
        formulaTotal: I18N_STORAGE_FORMULA_TOTAL,
        hasExpiration: true,
        pricePerUnit: I18N_STORAGE_PRICE_PER_UNIT,
        productLabel: I18N_STORAGE_PRODUCT_LABEL,
        productUnit: I18N_STORAGE_PRODUCT_UNIT,
        quantityPerPack: STORAGE_PER_PACK,
        summaryTitle: i18nStorageSummaryTitle,
        summaryTotal: I18N_STORAGE_SUMMARY_TOTAL,
        title: I18N_STORAGE_TITLE,
      };
    },
  },
};
</script>
<template>
  <buy-addons-app :config="config" :tags="tags" />
</template>
