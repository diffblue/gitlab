import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';
import { __, s__ } from '~/locale';
import { PASSED, PENDING } from 'ee/ci/reports/status_checks_report/constants';

export function getFailedChecksWithLoadingState(failedStatusChecks, statusCheckId) {
  return failedStatusChecks.map((failedStatusCheck) => {
    if (failedStatusCheck.id !== statusCheckId) {
      return failedStatusCheck;
    }

    const { actions, ...rest } = failedStatusCheck;

    // omit icon since loading spinner will appear
    const { icon, ...action } = actions[0];

    return {
      ...rest,
      actions: [
        {
          ...action,
          loading: true,
          disabled: true,
        },
      ],
    };
  });
}

function mapStatusCheck(statusCheck, iconName) {
  return {
    id: statusCheck.id,
    text: `${statusCheck.name}: %{small_start}${statusCheck.external_url}%{small_end}`,
    subtext: `%{small_start}${s__('StatusCheck|Status Check ID')}: ${statusCheck.id}%{small_end}`,
    icon: { name: iconName },
  };
}

function mapFailedStatusCheck(statusCheck, canRetry, onRetryCallback) {
  const row = mapStatusCheck(statusCheck, EXTENSION_ICONS.failed);

  if (canRetry) {
    row.actions = [
      {
        icon: 'retry',
        text: __('Retry'),
        onClick: () => onRetryCallback(statusCheck),
      },
    ];
  }

  return row;
}

export function mapStatusCheckResponse(response, options, onRetryCallback) {
  const { canRetry } = options;
  const approved = [];
  const pending = [];
  const failed = [];

  response.data.forEach((statusCheck) => {
    switch (statusCheck.status) {
      case PASSED:
        approved.push(mapStatusCheck(statusCheck, EXTENSION_ICONS.success));
        break;
      case PENDING:
        pending.push(mapStatusCheck(statusCheck, EXTENSION_ICONS.neutral));
        break;
      default:
        failed.push(mapFailedStatusCheck(statusCheck, canRetry, onRetryCallback));
    }
  });

  return { approved, pending, failed };
}
