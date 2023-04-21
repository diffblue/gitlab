export const ciCatalogResourcesItemsCount = 20;

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
      CiCatalogResource: {
        fields: {
          lastUpdate: {
            read() {
              return { time: new Date(), user: { id: 1, name: 'FinnTheHuman', webUrl: '' } };
            },
          },
          latestVersion: {
            read() {
              return '1.0.0';
            },
          },
          group: {
            read() {
              return 'jake_and_others';
            },
          },
          namespace: {
            read() {
              return 'Adventure_Time';
            },
          },
          statistics: {
            read() {
              return { forks: 4, favorites: 28 };
            },
          },
        },
      },
    },
  },
};
