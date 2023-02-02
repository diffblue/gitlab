import Vue from 'vue';
import TrialStatusPopover from './components/trial_status_popover.vue';
import TrialStatusWidget from './components/trial_status_widget.vue';

export const initTrialStatusWidget = () => {
  const el = document.getElementById('js-trial-status-widget');

  if (!el) return undefined;

  const {
    containerId,
    trialDaysUsed,
    trialDuration,
    navIconImagePath,
    percentageComplete,
    planName,
    plansHref,
  } = el.dataset;

  return new Vue({
    el,
    provide: {
      containerId,
      trialDaysUsed: Number(trialDaysUsed) || 0,
      trialDuration: Number(trialDuration) || 0,
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
    daysRemaining,
    planName,
    plansHref,
    targetId,
    trialEndDate,
    namespaceId,
    userName,
    firstName,
    lastName,
    companyName,
    glmContent,
  } = el.dataset;

  return new Vue({
    el,
    provide: {
      containerId,
      daysRemaining,
      planName,
      plansHref,
      targetId,
      trialEndDate: new Date(trialEndDate),
      user: {
        namespaceId,
        userName,
        firstName,
        lastName,
        companyName,
        glmContent,
      },
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
