import {
  CI_MINUTES_PER_PACK,
  I18N_CI_MINUTES_PRODUCT_LABEL,
  I18N_CI_MINUTES_PRODUCT_UNIT,
  I18N_STORAGE_PRODUCT_LABEL,
  I18N_STORAGE_PRODUCT_UNIT,
  planCode,
  STORAGE_PER_PACK,
} from 'ee/subscriptions/buy_addons_shared/constants';

export const planData = {
  [planCode.CI_1000_MINUTES_PLAN]: {
    hasExpiration: false,
    isAddon: true,
    label: I18N_CI_MINUTES_PRODUCT_LABEL,
    productUnit: I18N_CI_MINUTES_PRODUCT_UNIT,
    quantityPerPack: CI_MINUTES_PER_PACK,
  },
  [planCode.STORAGE_PLAN]: {
    hasExpiration: true,
    isAddon: true,
    label: I18N_STORAGE_PRODUCT_LABEL,
    productUnit: I18N_STORAGE_PRODUCT_UNIT,
    quantityPerPack: STORAGE_PER_PACK,
  },
};
