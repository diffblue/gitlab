import { sprintf, __, s__, n__ } from '~/locale';

export const lastXDays = __('Last %{days} days');

const i18n = {
  header: {
    title: s__('RepositoriesAnalytics|Repositories Analytics'),
    description: s__(
      "RepositoriesAnalytics|Analyze repositories for projects in %{groupName}. Data doesn't include projects in subgroups. %{learnMoreLink}.",
    ),
  },
  summary: {
    codeCoverageHeader: s__('RepositoriesAnalytics|Test Code Coverage'),
    lastUpdated: s__('RepositoriesAnalytics|Last updated %{timeAgo}'),
    emptyChart: s__('RepositoriesAnalytics|No test coverage to display'),
    graphCardHeader: s__('RepositoriesAnalytics|Average test coverage'),
    graphCardSubheader: sprintf(lastXDays, { days: 30 }),
    yAxisName: __('Coverage'),
    xAxisName: __('Date'),
    graphName: s__('RepositoriesAnalytics|Average coverage'),
    graphTooltip: {
      averageCoverage: s__('RepositoriesAnalytics|Code Coverage: %{averageCoverage}'),
      projectCount: s__('RepositoriesAnalytics|Projects with Coverage: %{projectCount}'),
      coverageCount: s__('RepositoriesAnalytics|Jobs with Coverage: %{coverageCount}'),
    },
    metrics: {
      projectCountLabel: s__('RepositoriesAnalytics|Projects with Coverage'),
      projectCountPopover: (value) =>
        n__(
          'RepositoriesAnalytics|In the last day, %{metricValue} project in %{groupName} has code coverage enabled.',
          'RepositoriesAnalytics|In the last day, %{metricValue} projects in %{groupName} have code coverage enabled.',
          value,
        ),
      averageCoverageLabel: s__('RepositoriesAnalytics|Average Coverage by Job'),
      averageCoveragePopover: () =>
        s__(
          'RepositoriesAnalytics|In the last day, on average, %{metricValue} of all jobs are covered.',
        ),
      coverageCountLabel: s__('RepositoriesAnalytics|Jobs with Coverage'),
      coverageCountPopover: (value) =>
        n__(
          'RepositoriesAnalytics|In the last day, %{metricValue} job has code coverage.',
          'RepositoriesAnalytics|In the last day, %{metricValue} jobs have code coverage.',
          value,
        ),
    },
  },
  download: {
    downloadTestCoverageHeader: s__('RepositoriesAnalytics|Download historic test coverage data'),
    downloadCSVButton: s__('RepositoriesAnalytics|Download historic test coverage data (.csv)'),
    dateRangeHeader: __('Date range'),
    downloadCSVModalButton: s__('RepositoriesAnalytics|Download test coverage data (.csv)'),
    downloadCSVModalDescription: s__(
      'RepositoriesAnalytics|Historic Test Coverage Data is available in raw format (.csv) for further analysis.',
    ),
    projectDropdownHeader: __('Projects'),
    projectSelectAll: __('Select all'),
    queryErrorMessage: s__('RepositoriesAnalytics|There was an error fetching the projects.'),
  },
  table: {
    header: s__('RepositoriesAnalytics|Latest test coverage results'),
    emptyStateTitle: s__('RepositoriesAnalytics|Please select projects to display.'),
    emptyStateDescription: s__(
      'RepositoriesAnalytics|Please select a project or multiple projects to display their most recent test coverage data.',
    ),
    popover: s__(
      'RepositoriesAnalytics|Latest test coverage results for all projects in %{groupName} (excluding projects in subgroups).',
    ),
  },
};

export const headeri18n = i18n.header;
export const summaryi18n = i18n.summary;
export const downloadi18n = i18n.download;
export const tablei18n = i18n.table;
