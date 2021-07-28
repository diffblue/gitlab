import { n__, s__ } from '~/locale';

const CLICK_BUTTON_ACTION = 'click_button';
const RESIZE_EVENT_DEBOUNCE_MS = 150;

export const RESIZE_EVENT = 'resize';
export const EXPERIMENT_KEY = 'forcibly_show_trial_status_popover';
export const TRACKING_PROPERTY_WHEN_FORCED = 'forced';
export const TRACKING_PROPERTY_WHEN_VOLUNTARY = 'voluntary';

export const WIDGET = {
  i18n: {
    widgetTitle: {
      countableTranslator(count) {
        return n__(
          'Trials|%{planName} Trial %{enDash} %{num} day left',
          'Trials|%{planName} Trial %{enDash} %{num} days left',
          count,
        );
      },
    },
  },
  trackingEvents: {
    widgetClick: {
      action: 'click_link',
      label: 'trial_status_widget',
      property: TRACKING_PROPERTY_WHEN_VOLUNTARY,
    },
  },
};

export const POPOVER = {
  i18n: {
    close: s__('Modal|Close'),
    compareAllButtonTitle: s__('Trials|Compare all plans'),
    popoverTitle: s__('Trials|Hey there'),
    popoverContent: s__(`Trials|Your trial ends on
      %{boldStart}%{trialEndDate}%{boldEnd}. We hope you’re enjoying the
      features of GitLab %{planName}. To keep those features after your trial
      ends, you’ll need to buy a subscription. (You can also choose GitLab
      Premium if it meets your needs.)`),
    upgradeButtonTitle: s__('Trials|Upgrade %{groupName} to %{planName}'),
  },
  trackingEvents: {
    popoverShown: { action: 'popover_shown', label: 'trial_status_popover' },
    closeBtnClick: { action: CLICK_BUTTON_ACTION, label: 'close_popover' },
    upgradeBtnClick: { action: CLICK_BUTTON_ACTION, label: 'upgrade_to_ultimate' },
    compareBtnClick: { action: CLICK_BUTTON_ACTION, label: 'compare_all_plans' },
  },
  resizeEventDebounceMS: RESIZE_EVENT_DEBOUNCE_MS,
  disabledBreakpoints: ['xs', 'sm'],
  trialEndDateFormatString: 'mmmm d',
};
