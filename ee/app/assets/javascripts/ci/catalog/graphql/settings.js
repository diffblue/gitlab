export const ciCatalogResourcesItemsCount = 20;
export const CI_CATALOG_RESOURCE_TYPE = 'Ci::Catalog::Resource';

export const cacheConfig = {
  cacheConfig: {
    typePolicies: {
      Query: {
        fields: {
          ciCatalogResources: {
            keyArgs: false,
          },
        },
      },
    },
  },
};
