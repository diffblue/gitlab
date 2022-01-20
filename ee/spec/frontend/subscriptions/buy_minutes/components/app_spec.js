import BuyAddonsApp from 'ee/subscriptions/buy_addons_shared/components/app.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import App from 'ee/subscriptions/buy_minutes/components/app.vue';
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

describe('Buy Minutes App', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(App);
  };

  const findBuyAddonsApp = () => wrapper.findComponent(BuyAddonsApp);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('passes the correct tags', () => {
    expect(findBuyAddonsApp().props('tags')).toEqual([planTags.CI_1000_MINUTES_PLAN]);
  });

  it('passes the correct config', () => {
    expect(findBuyAddonsApp().props('config')).toMatchObject({
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
    });
  });
});
