import {
  mockDependencyProxyResponse,
  mockedNamespaceStorageResponse,
} from 'ee_jest/usage_quotas/storage/mock_data';
import createMockApollo from 'helpers/mock_apollo_helper';
import { storageTypeHelpPaths as helpLinks } from '~/usage_quotas/storage/constants';
import getNamespaceStorageQuery from 'ee/usage_quotas/storage/queries/namespace_storage.query.graphql';
import getDependencyProxyTotalSizeQuery from 'ee/usage_quotas/storage/queries/dependency_proxy_usage.query.graphql';
import NamespaceStorageApp from './namespace_storage_app.vue';

const meta = {
  title: 'ee/usage_quotas/storage/namespace_storage_app',
  component: NamespaceStorageApp,
};

export default meta;

const createTemplate = (config = {}) => {
  let { provide, apolloProvider } = config;

  if (provide == null) {
    provide = {};
  }

  if (apolloProvider == null) {
    const requestHandlers = [
      [getNamespaceStorageQuery, () => Promise.resolve(mockedNamespaceStorageResponse)],
      [getDependencyProxyTotalSizeQuery, () => Promise.resolve(mockDependencyProxyResponse)],
    ];
    apolloProvider = createMockApollo(requestHandlers);
  }

  return (args, { argTypes }) => ({
    components: { NamespaceStorageApp },
    apolloProvider,
    provide: {
      namespaceId: '1',
      namespacePath: '/namespace/',
      userNamespace: false,
      defaultPerPage: 20,
      namespacePlanName: 'free',
      namespacePlanStorageIncluded: '40',
      purchaseStorageUrl: '//purchase-storage-url',
      buyAddonTargetAttr: 'buyAddonTargetAttr',
      enforcementType: 'namespace_storage_limit',
      isUsingProjectEnforcement: false,
      helpLinks,
      ...provide,
    },
    props: Object.keys(argTypes),
    template: '<namespace-storage-app />',
  });
};

export const NamespaceTypeStorageLimits = {
  render: createTemplate(),
};

export const ProjectTypeStorageLimits = {
  render: createTemplate({
    provide: {
      enforcementType: 'project_repository_limit',
      isUsingProjectEnforcement: true,
    },
  }),
};

export const Loading = {
  render: (...args) => {
    const apolloProvider = createMockApollo([
      [getNamespaceStorageQuery, () => new Promise(() => {})],
      [getDependencyProxyTotalSizeQuery, () => new Promise(() => {})],
    ]);

    return createTemplate({
      apolloProvider,
    })(...args);
  },
};

export const LoadingError = {
  render: (...args) => {
    const apolloProvider = createMockApollo([
      [getNamespaceStorageQuery, () => Promise.reject()],
      [getDependencyProxyTotalSizeQuery, () => Promise.reject()],
    ]);

    return createTemplate({
      apolloProvider,
    })(...args);
  },
};
