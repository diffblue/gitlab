import devopsAdoptionOverviewChartJson from 'test_fixtures/graphql/analytics/devops_reports/devops_adoption/graphql/queries/devops_adoption_overview_chart.query.graphql.json';
import devopsAdoptionEnabledNamespacesJson from 'test_fixtures/graphql/analytics/devops_reports/devops_adoption/graphql/queries/devops_adoption_enabled_namespaces.query.graphql.json';
import { DEVOPS_ADOPTION_TABLE_CONFIGURATION } from 'ee/analytics/devops_reports/devops_adoption/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

export const namespaceWithSnapotsData = devopsAdoptionOverviewChartJson;

export const devopsAdoptionNamespaceData =
  devopsAdoptionEnabledNamespacesJson.data.devopsAdoptionEnabledNamespaces;

export const groupData = devopsAdoptionNamespaceData.nodes.map((node) => {
  return {
    fullName: node.namespace.fullName,
    id: getIdFromGraphQLId(node.namespace.id),
  };
});

export const groupNodes = groupData.map((group) => {
  return {
    __typename: 'Group',
    ...group,
  };
});

export const groupGids = devopsAdoptionNamespaceData.nodes.map((node) => node.namespace.id);

export const devopsAdoptionTableHeaders = [
  {
    index: 0,
    label: 'Group',
    tooltip: null,
  },
  {
    index: 1,
    label: 'Approvals',
    tooltip: 'At least one approval on a merge request',
  },
  {
    index: 2,
    label: 'Code owners',
    tooltip: 'Code owners enabled for at least one project',
  },
  {
    index: 3,
    label: 'Issues',
    tooltip: 'At least one issue created',
  },
  {
    index: 4,
    label: 'MRs',
    tooltip: 'At least one merge request created',
  },
  {
    index: 5,
    label: '',
    tooltip: null,
  },
];

export const genericErrorMessage = 'An error occurred while saving changes. Please try again.';

export const dataErrorMessage = 'Name already taken.';

export const genericDeleteErrorMessage =
  'An error occurred while removing the group. Please try again.';

const firstNodelatestSnapshot = devopsAdoptionNamespaceData.nodes[0].latestSnapshot;

const sortedFeatures = DEVOPS_ADOPTION_TABLE_CONFIGURATION.reduce(
  (features, section) => [...features, ...section.cols],
  [],
);

export const overallAdoptionData = {
  displayMeta: false,
  featureMeta: sortedFeatures.map((feature) => {
    return {
      title: feature.label,
      adopted: Boolean(firstNodelatestSnapshot[feature.key]),
    };
  }),
  icon: 'tanuki',
  title: 'Overall adoption',
  variant: 'primary',
};
