import { s__ } from '~/locale';

const CLICK_BUTTON_ACTION = 'click_button';
const RESIZE_EVENT_DEBOUNCE_MS = 150;

export const RESIZE_EVENT = 'resize';

export const WIDGET = {
  i18n: {
    widgetTitle: s__('Trials|%{planName} Trial'),
    widgetRemainingDays: s__('Trials|Day %{daysUsed}/%{duration}'),
  },
  trackingEvents: {
    widgetClick: { action: 'click_link', label: 'trial_status_widget' },
  },
};

export const POPOVER = {
  i18n: {
    close: s__('Modal|Close'),
    compareAllButtonTitle: s__('Trials|Compare all plans'),
    popoverContent: s__(`Trials|Your trial ends on
      %{boldStart}%{trialEndDate}%{boldEnd}. We hope you’re enjoying the
      features of GitLab %{planName}. To keep those features after your trial
      ends, you’ll need to buy a subscription. (You can also choose GitLab
      Premium if it meets your needs.)`),
  },
  trackingEvents: {
    popoverShown: { action: 'popover_shown', label: 'trial_status_popover' },
    contactSalesBtnClick: { action: CLICK_BUTTON_ACTION, label: 'contact_sales' },
    compareBtnClick: { action: CLICK_BUTTON_ACTION, label: 'compare_all_plans' },
  },
  resizeEventDebounceMS: RESIZE_EVENT_DEBOUNCE_MS,
  disabledBreakpoints: ['xs', 'sm'],
  trialEndDateFormatString: 'mmmm d',
};
