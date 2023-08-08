import { s__ } from '~/locale';

const ACTIVE_TRIAL_POPOVER = 'trial_status_popover';
const TRIAL_ENDED_POPOVER = 'trial_ended_popover';
const CLICK_BUTTON_ACTION = 'click_button';
const RESIZE_EVENT_DEBOUNCE_MS = 150;

export const RESIZE_EVENT = 'resize';

export const WIDGET = {
  i18n: {
    widgetTitle: s__('Trials|%{planName} Trial'),
    widgetRemainingDays: s__('Trials|Day %{daysUsed}/%{duration}'),
    widgetTitleExpiredTrial: s__('Trials|Your 30-day trial has ended'),
    widgetBodyExpiredTrial: s__('Trials|Looking to do more with GitLab?'),
  },
  trackingEvents: {
    action: 'click_link',
    activeTrialOptions: {
      category: 'trial_status_widget',
      label: 'ultimate_trial',
    },
    trialEndedOptions: {
      category: 'trial_ended_widget',
      label: 'your_30_day_trial_has_ended',
    },
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
    popoverTitleExpiredTrial: s__('Trials|Upgrade your plan for more security features'),
    popoverContentExpiredTrial: s__(
      'Trials|With GitLab Ultimate you can detect and address vulnerabilities in your application.',
    ),
  },
  trackingEvents: {
    activeTrialCategory: ACTIVE_TRIAL_POPOVER,
    trialEndedCategory: TRIAL_ENDED_POPOVER,
    popoverShown: { action: 'render_popover' },
    contactSalesBtnClick: {
      action: CLICK_BUTTON_ACTION,
      label: 'contact_sales',
    },
    compareBtnClick: {
      action: CLICK_BUTTON_ACTION,
      label: 'compare_all_plans',
    },
  },
  resizeEventDebounceMS: RESIZE_EVENT_DEBOUNCE_MS,
  disabledBreakpoints: ['xs', 'sm'],
  trialEndDateFormatString: 'mmmm d',
};
