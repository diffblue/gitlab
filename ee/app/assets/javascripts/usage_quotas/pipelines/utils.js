import { formatDate } from '~/lib/utils/datetime_utility';

export const getProjectMinutesUsage = (project, ciMinutesUsageData) => {
  const currentMonth = formatDate(Date.now(), 'yyyy-mm');
  const currentMonthMinutesUsage = ciMinutesUsageData.find((minutes) =>
    minutes.monthIso8601.startsWith(currentMonth),
  );

  if (!currentMonthMinutesUsage) {
    return 0;
  }

  const projectMinutesUsage = currentMonthMinutesUsage.projects.nodes.find(
    (node) => project.name === node.name,
  );

  return !projectMinutesUsage ? 0 : projectMinutesUsage.minutes;
};
