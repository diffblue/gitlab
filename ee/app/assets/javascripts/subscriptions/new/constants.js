import { s__ } from '~/locale';

export const TAX_RATE = 0;
export const NEW_GROUP = 'new_group';
export const ULTIMATE = 'ultimate';

export const PurchaseEvent = Object.freeze({
  ERROR: 'error',
  ERROR_RESET: 'error-reset',
});

export const CHARGE_PROCESSING_TYPE = 'Charge';
export const DISCOUNT_PROCESSING_TYPE = 'Discount';

export const VALIDATION_ERROR_CODE = 'VALIDATION_ERROR';
export const PROMO_CODE_ERROR_ATTRIBUTE = 'promo_code';
export const INVALID_PROMO_CODE_ERROR_CODE = 'INVALID';

export const INVALID_PROMO_CODE_ERROR_MESSAGE = s__(
  'Checkout|Invalid coupon code. Enter a valid coupon code.',
);
export const PROMO_CODE_SUCCESS_MESSAGE = s__(
  `Checkout|Coupon has been applied and by continuing with your purchase, you accept and agree to the %{linkStart}Coupon Terms%{linkEnd}.`,
);
export const PROMO_CODE_USER_QUANTITY_ERROR_MESSAGE = s__(
  'Checkout|Add active users before adding a coupon.',
);

export const PROMO_CODE_OFFER_TEXT = s__(
  'Checkout|Pricing reflective of %{linkStart}limited-time offer%{linkEnd}.',
);

export const PROMO_CODE_TERMS_LINK = 'https://about.gitlab.com/pricing/terms/';
