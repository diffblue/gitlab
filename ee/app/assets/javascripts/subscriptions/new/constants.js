import { s__ } from '~/locale';

const CLICK_BUTTON_ACTION = 'click_button';
const MODAL_RENDERED_ACTION = 'modal_rendered';

export const TAX_RATE = 0;
export const MODAL_TIMEOUT = 180000; // 3 minutes
export const NEW_GROUP = 'new_group';
export const ULTIMATE = 'ultimate';
export const MODAL_TITLE = s__('Subscriptions|Not ready to buy yet?');
export const MODAL_CLOSE_BTN = s__('Subscriptions|Close');
export const MODAL_CHAT_SALES_BTN = s__('Subscriptions|Chat with sales');
export const MODAL_START_TRIAL_BTN = s__('Subscriptions|Start a free trial');
export const MODAL_BODY = s__(
  "Subscriptions|We understand. Maybe you have some questions for our sales team, or maybe you'd like to try some of the paid features first. What would you like to do?",
);

export const TRACKING_EVENTS = {
  startFreeTrial: { action: CLICK_BUTTON_ACTION, label: 'start_free_trial' },
  talkToSales: { action: CLICK_BUTTON_ACTION, label: 'talk_to_sales' },
  cancel: { action: CLICK_BUTTON_ACTION, label: 'cancel' },
  dismiss: { action: CLICK_BUTTON_ACTION, label: 'dismiss' },
  modalRendered: { action: MODAL_RENDERED_ACTION, label: 'modal_rendered' },
};

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
export const PROMO_CODE_TERMS_LINK = 'https://about.gitlab.com/pricing/terms/';
