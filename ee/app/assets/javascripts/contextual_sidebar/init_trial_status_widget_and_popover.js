import Vue from 'vue';
import TrialStatusPopover from './components/trial_status_popover.vue';
import TrialStatusWidget from './components/trial_status_widget.vue';

export const initTrialStatusWidget = () => {
  const el = document.getElementById('js-trial-status-widget');

  if (!el) return undefined;

  const {
    containerId,
    daysRemaining,
    navIconImagePath,
    percentageComplete,
    planName,
    plansHref,
  } = el.dataset;

  return new Vue({
    el,
    provide: {
      containerId,
      daysRemaining: Number(daysRemaining),
      navIconImagePath,
      percentageComplete: Number(percentageComplete),
      planName,
      plansHref,
    },
    render: (createElement) => createElement(TrialStatusWidget),
  });
};

export const initTrialStatusPopover = () => {
  const el = document.getElementById('js-trial-status-popover');

  if (!el) return undefined;

  const {
    containerId,
    daysRemaining, // for tracking purposes
    groupName,
    planName,
    plansHref,
    purchaseHref,
    startInitiallyShown,
    targetId,
    trialEndDate,
    userCalloutsPath,
    userCalloutsFeatureId,
  } = el.dataset;

  return new Vue({
    el,
    provide: {
      containerId,
      daysRemaining, // for tracking purposes
      groupName,
      planName,
      plansHref,
      purchaseHref,
      startInitiallyShown: startInitiallyShown !== undefined,
      targetId,
      trialEndDate: new Date(trialEndDate),
      userCalloutsPath,
      userCalloutsFeatureId,
    },
    render: (createElement) => createElement(TrialStatusPopover),
  });
};

export const initTrialStatusWidgetAndPopover = () => {
  return {
    widget: initTrialStatusWidget(),
    popover: initTrialStatusPopover(),
  };
};
