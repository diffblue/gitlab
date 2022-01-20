import BuyAddonsApp from 'ee/subscriptions/buy_addons_shared/components/app.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import App from 'ee/subscriptions/buy_storage/components/app.vue';
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

describe('Buy Storage App', () => {
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
    expect(findBuyAddonsApp().props('tags')).toEqual([planTags.STORAGE_PLAN]);
  });

  it('passes the correct config', () => {
    expect(findBuyAddonsApp().props('config')).toMatchObject({
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
    });
  });
});
