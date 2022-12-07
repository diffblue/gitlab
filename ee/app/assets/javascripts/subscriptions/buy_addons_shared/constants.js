import { s__, n__ } from '~/locale';

/* eslint-disable @gitlab/require-i18n-strings */
export const planTags = {
  CI_1000_MINUTES_PLAN: 'CI_1000_MINUTES_PLAN',
  STORAGE_PLAN: 'STORAGE_PLAN',
};
/* eslint-enable @gitlab/require-i18n-strings */

export const CUSTOMERSDOT_CLIENT = 'customersDotClient';
export const GITLAB_CLIENT = 'gitlabClient';
export const CUSTOMER_TYPE = 'Customer';
export const SUBSCRIPTION_TYPE = 'Subscription';
export const NAMESPACE_TYPE = 'Namespace';
export const PAYMENT_METHOD_TYPE = 'PaymentMethod';
export const ORDER_PREVIEW_TYPE = 'OrderPreview';
export const PLAN_TYPE = 'Plan';
export const STEP_TYPE = 'Step';
export const COUNTRY_TYPE = 'Country';
export const STATE_TYPE = 'State';

export const CI_MINUTES_PER_PACK = 1000;
export const STORAGE_PER_PACK = 10;

// CI Minutes addon data translations
export const I18N_CI_MINUTES_PRODUCT_LABEL = s__('Checkout|CI minute pack');
export const I18N_CI_MINUTES_PRODUCT_UNIT = s__('Checkout|minutes');

// Storage addon translations
export const I18N_STORAGE_PRODUCT_LABEL = s__('Checkout|Storage packs');
export const I18N_STORAGE_PRODUCT_UNIT = s__('Checkout|GB');
export const I18N_STORAGE_TOOLTIP_NOTE = s__(
  'Checkout|Your storage subscription has the same term as your main subscription, and the price is prorated accordingly.',
);

// Shared addon translations
export const I18N_DETAILS_STEP_TITLE = s__('Checkout|Purchase details');
export const I18N_DETAILS_NEXT_STEP_BUTTON_TEXT = s__('Checkout|Continue to billing');
export const I18N_DETAILS_INVALID_QUANTITY_MESSAGE = s__(
  'Checkout|Must be 1 or more. Cannot be a decimal.',
);
export const I18N_DETAILS_FORMULA = s__('Checkout|x %{quantity} %{units} per pack =');
export const I18N_DETAILS_FORMULA_WITH_ALERT = s__('Checkout|x %{quantity} %{units} per pack');

// Summary translations
export const I18N_SUMMARY_QUANTITY = s__('Checkout|(x%{quantity})');
export const I18N_SUMMARY_DATES = s__('Checkout|%{startDate} - %{endDate}');
export const I18N_SUMMARY_SUBTOTAL = s__('Checkout|Subtotal');
export const I18N_SUMMARY_TAX = s__('Checkout|Tax');
export const I18N_SUMMARY_TAX_NOTE = s__(
  'Checkout|(may be %{linkStart}charged upon purchase%{linkEnd})',
);
export const I18N_SUMMARY_TOTAL = s__('Checkout|Total');

export const I18N_API_ERROR = s__(
  'Checkout|An unknown error has occurred. Please try again by refreshing this page.',
);

// Addon label translations
export const I18N_CI_1000_MINUTES_PLAN = {
  alertText: s__(
    "Checkout|CI minute packs are only used after you've used your subscription's monthly quota. The additional minutes will roll over month to month and are valid for one year.",
  ),
  formula: I18N_DETAILS_FORMULA,
  formulaWithAlert: I18N_DETAILS_FORMULA_WITH_ALERT,
  formulaTotal: s__('Checkout|%{quantity} CI minutes'),
  pricePerUnit: s__('Checkout|$%{selectedPlanPrice} per pack of 1,000 minutes'),
  summaryTitle: (quantity) =>
    n__('Checkout|%d CI minute pack', 'Checkout|%d CI minute packs', quantity),
  summaryTotal: s__('Checkout|Total minutes: %{quantity}'),
  title: s__("Checkout|%{name}'s CI minutes"),
};

export const I18N_STORAGE_PLAN = {
  alertText: '',
  formula: I18N_DETAILS_FORMULA,
  formulaWithAlert: I18N_DETAILS_FORMULA_WITH_ALERT,
  formulaTotal: s__('Checkout|%{quantity} GB of storage'),
  pricePerUnit: s__('Checkout|$%{selectedPlanPrice} per 10 GB storage pack per year'),
  summaryTitle: (quantity) =>
    n__('Checkout|%{quantity} storage pack', 'Checkout|%{quantity} storage packs', quantity),
  summaryTotal: s__('Checkout|Total storage: %{quantity} GB'),
  title: s__("Checkout|%{name}'s storage subscription"),
};
