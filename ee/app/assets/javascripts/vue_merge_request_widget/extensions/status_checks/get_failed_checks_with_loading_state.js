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
