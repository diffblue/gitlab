export const getGroupDataTransferEgressResponse = {
  data: {
    group: {
      id: 'gid://gitlab/Group/90',
      dataTransfer: {
        egressNodes: {
          nodes: [
            { date: '2023-01-01', totalEgress: '5000861558', __typename: 'EgressNode' },
            { date: '2023-02-01', totalEgress: '6651307793', __typename: 'EgressNode' },
            { date: '2023-03-01', totalEgress: '5368547376', __typename: 'EgressNode' },
            { date: '2023-04-01', totalEgress: '4055795925', __typename: 'EgressNode' },
          ],
          __typename: 'EgressNodeConnection',
        },
        __typename: 'GroupDataTransfer',
      },
      __typename: 'Group',
      projects: {
        __typename: 'ProjectConnection',
        pageInfo: {
          __typename: 'PageInfo',
          endCursor: 'eyJpZCI6IjE5In0',
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: 'eyJpZCI6IjM2In0',
        },
        nodes: [
          {
            __typename: 'Project',
            id: 'gid://gitlab/Project/36',
            webUrl: 'http://127.0.0.1:3000/gitlab-instance-f284d23a/gitlab-profile',
            name: 'gitlab-profile',
            nameWithNamespace: 'GitLab Instance / gitlab-profile',
            avatarUrl: null,
            dataTransfer: {
              __typename: 'ProjectDataTransfer',
              egressNodes: {
                __typename: 'EgressNodeConnection',
                nodes: [
                  { __typename: 'EgressNode', totalEgress: '1044649' },
                  { __typename: 'EgressNode', totalEgress: '914083' },
                  { __typename: 'EgressNode', totalEgress: '1754180' },
                  { __typename: 'EgressNode', totalEgress: '994833' },
                  { __typename: 'EgressNode', totalEgress: '1352749' },
                  { __typename: 'EgressNode', totalEgress: '1071535' },
                  { __typename: 'EgressNode', totalEgress: '1601390' },
                  { __typename: 'EgressNode', totalEgress: '1111285' },
                  { __typename: 'EgressNode', totalEgress: '1709606' },
                  { __typename: 'EgressNode', totalEgress: '1444238' },
                  { __typename: 'EgressNode', totalEgress: '831346' },
                  { __typename: 'EgressNode', totalEgress: '923609' },
                ],
              },
            },
          },
          {
            __typename: 'Project',
            id: 'gid://gitlab/Project/31',
            webUrl: 'http://127.0.0.1:3000/gitlab-instance-f284d23a/testing1',
            name: 'testing1',
            nameWithNamespace: 'GitLab Instance / testing1',
            avatarUrl: null,
            dataTransfer: {
              __typename: 'ProjectDataTransfer',
              egressNodes: {
                __typename: 'EgressNodeConnection',
                nodes: [
                  { __typename: 'EgressNode', totalEgress: '1288794' },
                  { __typename: 'EgressNode', totalEgress: '1582709' },
                  { __typename: 'EgressNode', totalEgress: '1520123' },
                  { __typename: 'EgressNode', totalEgress: '1378005' },
                  { __typename: 'EgressNode', totalEgress: '1599937' },
                  { __typename: 'EgressNode', totalEgress: '1039529' },
                  { __typename: 'EgressNode', totalEgress: '1290278' },
                  { __typename: 'EgressNode', totalEgress: '1017761' },
                  { __typename: 'EgressNode', totalEgress: '1362105' },
                  { __typename: 'EgressNode', totalEgress: '1329017' },
                  { __typename: 'EgressNode', totalEgress: '1126241' },
                  { __typename: 'EgressNode', totalEgress: '743849' },
                ],
              },
            },
          },
          {
            __typename: 'Project',
            id: 'gid://gitlab/Project/28',
            webUrl: 'http://127.0.0.1:3000/gitlab-instance-f284d23a/gitlab-meta',
            name: 'gitlab-meta',
            nameWithNamespace: 'GitLab Instance / gitlab-meta',
            avatarUrl: null,
            dataTransfer: {
              __typename: 'ProjectDataTransfer',
              egressNodes: {
                __typename: 'EgressNodeConnection',
                nodes: [
                  { __typename: 'EgressNode', totalEgress: '1459859' },
                  { __typename: 'EgressNode', totalEgress: '1894488' },
                  { __typename: 'EgressNode', totalEgress: '1177318' },
                  { __typename: 'EgressNode', totalEgress: '1383908' },
                  { __typename: 'EgressNode', totalEgress: '1558347' },
                  { __typename: 'EgressNode', totalEgress: '1068744' },
                  { __typename: 'EgressNode', totalEgress: '987875' },
                  { __typename: 'EgressNode', totalEgress: '1362142' },
                  { __typename: 'EgressNode', totalEgress: '1410850' },
                  { __typename: 'EgressNode', totalEgress: '1531187' },
                  { __typename: 'EgressNode', totalEgress: '1255210' },
                  { __typename: 'EgressNode', totalEgress: '1221630' },
                ],
              },
            },
          },
          {
            __typename: 'Project',
            id: 'gid://gitlab/Project/26',
            webUrl: 'http://127.0.0.1:3000/gitlab-instance-f284d23a/.gitlab',
            name: '.gitlab',
            nameWithNamespace: 'GitLab Instance / .gitlab',
            avatarUrl: null,
            dataTransfer: {
              __typename: 'ProjectDataTransfer',
              egressNodes: {
                __typename: 'EgressNodeConnection',
                nodes: [
                  { __typename: 'EgressNode', totalEgress: '957464' },
                  { __typename: 'EgressNode', totalEgress: '1369318' },
                  { __typename: 'EgressNode', totalEgress: '1403520' },
                  { __typename: 'EgressNode', totalEgress: '1022219' },
                  { __typename: 'EgressNode', totalEgress: '1883300' },
                  { __typename: 'EgressNode', totalEgress: '1126821' },
                  { __typename: 'EgressNode', totalEgress: '1374093' },
                  { __typename: 'EgressNode', totalEgress: '1191342' },
                  { __typename: 'EgressNode', totalEgress: '1014697' },
                  { __typename: 'EgressNode', totalEgress: '872322' },
                  { __typename: 'EgressNode', totalEgress: '984927' },
                  { __typename: 'EgressNode', totalEgress: '868354' },
                ],
              },
            },
          },
          {
            __typename: 'Project',
            id: 'gid://gitlab/Project/19',
            webUrl: 'http://127.0.0.1:3000/gitlab-instance-f284d23a/Monitoring',
            name: 'Monitoring',
            nameWithNamespace: 'GitLab Instance / Monitoring',
            avatarUrl: 'http://127.0.0.1:3000/uploads/-/system/project/avatar/19/1516979960758.jpg',
            dataTransfer: {
              __typename: 'ProjectDataTransfer',
              egressNodes: {
                __typename: 'EgressNodeConnection',
                nodes: [
                  { __typename: 'EgressNode', totalEgress: '943850' },
                  { __typename: 'EgressNode', totalEgress: '1307215' },
                  { __typename: 'EgressNode', totalEgress: '1466762' },
                  { __typename: 'EgressNode', totalEgress: '1702687' },
                  { __typename: 'EgressNode', totalEgress: '1293623' },
                  { __typename: 'EgressNode', totalEgress: '1372053' },
                  { __typename: 'EgressNode', totalEgress: '1170349' },
                  { __typename: 'EgressNode', totalEgress: '1613637' },
                  { __typename: 'EgressNode', totalEgress: '1329256' },
                  { __typename: 'EgressNode', totalEgress: '1126149' },
                  { __typename: 'EgressNode', totalEgress: '1039698' },
                  { __typename: 'EgressNode', totalEgress: '1419843' },
                ],
              },
            },
          },
        ],
      },
    },
  },
};

export const getProjectDataTransferEgressResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/19',
      dataTransfer: {
        egressNodes: {
          nodes: [
            {
              totalEgress: '990437',
              repositoryEgress: '297083',
              artifactsEgress: '384262',
              packagesEgress: '273801',
              registryEgress: '35291',
              __typename: 'EgressNode',
            },
            {
              totalEgress: '885352',
              repositoryEgress: '191159',
              artifactsEgress: '232691',
              packagesEgress: '34886',
              registryEgress: '426616',
              __typename: 'EgressNode',
            },
            {
              totalEgress: '1321328',
              repositoryEgress: '336973',
              artifactsEgress: '347758',
              packagesEgress: '453503',
              registryEgress: '183094',
              __typename: 'EgressNode',
            },
            {
              totalEgress: '1419271',
              repositoryEgress: '402914',
              artifactsEgress: '462078',
              packagesEgress: '297757',
              registryEgress: '256522',
              __typename: 'EgressNode',
            },
            {
              totalEgress: '1461484',
              repositoryEgress: '329418',
              artifactsEgress: '462530',
              packagesEgress: '457680',
              registryEgress: '211856',
              __typename: 'EgressNode',
            },
            {
              totalEgress: '1118407',
              repositoryEgress: '265536',
              artifactsEgress: '313687',
              packagesEgress: '296911',
              registryEgress: '242273',
              __typename: 'EgressNode',
            },
            {
              totalEgress: '1275632',
              repositoryEgress: '218354',
              artifactsEgress: '413759',
              packagesEgress: '157842',
              registryEgress: '485677',
              __typename: 'EgressNode',
            },
            {
              totalEgress: '1295969',
              repositoryEgress: '102132',
              artifactsEgress: '488952',
              packagesEgress: '484891',
              registryEgress: '219994',
              __typename: 'EgressNode',
            },
            {
              totalEgress: '1109851',
              repositoryEgress: '482249',
              artifactsEgress: '208524',
              packagesEgress: '396962',
              registryEgress: '22116',
              __typename: 'EgressNode',
            },
            {
              totalEgress: '1389795',
              repositoryEgress: '276366',
              artifactsEgress: '237648',
              packagesEgress: '455132',
              registryEgress: '420649',
              __typename: 'EgressNode',
            },
            {
              totalEgress: '904109',
              repositoryEgress: '349951',
              artifactsEgress: '99778',
              packagesEgress: '421730',
              registryEgress: '32650',
              __typename: 'EgressNode',
            },
            {
              totalEgress: '1011054',
              repositoryEgress: '24256',
              artifactsEgress: '377353',
              packagesEgress: '365897',
              registryEgress: '243548',
              __typename: 'EgressNode',
            },
          ],
          __typename: 'EgressNodeConnection',
        },
        __typename: 'ProjectDataTransfer',
      },
      __typename: 'Project',
    },
  },
};
