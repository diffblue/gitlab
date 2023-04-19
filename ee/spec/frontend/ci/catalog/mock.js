const generateResourcesNodes = (count = 20, startId = 0) => {
  const nodes = [];
  for (let i = startId; i < startId + count; i += 1) {
    nodes.push({
      __typename: 'CiCatalogResource',
      id: `gid://gitlab/CiCatalogResource/${i}`,
      name: `My component #${i}`,
      group: 'awesome-group',
      namespace: 'my_namespace',
      description: `This is a component that does a bunch of stuff and is really just a number: ${i}`,
      icon: 'my-icon',
      lastUpdate: {
        time: Date.now(),
        user: { id: 1, webUrl: 'profile/1', name: 'username' },
      },
      statistics: {
        favorites: 1,
        forks: 12,
      },
    });
  }

  return nodes;
};

const generateCatalogResourcesResponse = ({
  nodes = [],
  pageInfo = {
    hasNextPage: true,
    hasPreviousPage: false,
    endCursor: 'aaaasdsad23dfadassdsa',
    startCursor: 'aaaasdsad23dfadassdsa',
  },
  totalCount = nodes.length,
}) => {
  return {
    data: {
      ciCatalogResources: {
        __typename: 'CiCatalogResourceConnection',
        pageInfo,
        count: totalCount,
        nodes,
      },
    },
  };
};

export const mockCatalogResourceItem = generateResourcesNodes(1)[0];

export const generateEmptyCatalogResponse = () =>
  generateCatalogResourcesResponse({
    pageInfo: {
      hasNextPage: false,
      hasPreviousPage: false,
      startCursor: null,
      endCursor: null,
    },
  });

export const generateCatalogResponseWithOnlyOnePage = () => {
  const nodes = generateResourcesNodes(5);
  return generateCatalogResourcesResponse({
    nodes,
    pageInfo: {
      hasNextPage: false,
      hasPreviousPage: false,
      startCursor: 'aaaaaaaaaaa',
      endCursor: 'aaaaaaaaaaa',
    },
  });
};

export const generateCatalogResponse = () => {
  const nodes = generateResourcesNodes();
  return generateCatalogResourcesResponse({ nodes, totalCount: 25 });
};

export const generateCatalogResponsePage2 = () => {
  const nodes = generateResourcesNodes(20, 20);
  return generateCatalogResourcesResponse({
    nodes,
    pageInfo: {
      hasNextPage: true,
      hasPreviousPage: true,
      startCursor: 'bbbbbbbbbb',
      endCursor: 'ccccccccccc',
    },
    totalCount: 70,
  });
};

export const generateCatalogResponseLastPage = () => {
  const nodes = generateResourcesNodes();
  return generateCatalogResourcesResponse({
    nodes,
    pageInfo: {
      hasNextPage: false,
      hasPreviousPage: true,
      startCursor: 'bbbbbbbbbb',
      endCursor: 'ccccccccccc',
    },
    totalCount: 39,
  });
};
