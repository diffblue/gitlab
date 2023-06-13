export const ciCatalogResourcesItemsCount = 20;

export const catalogDetailsMock = {
  id: 1,
  icon: null,
  // eslint-disable-next-line @gitlab/require-i18n-strings
  description: 'This is the description of the repo',
  // eslint-disable-next-line @gitlab/require-i18n-strings
  name: 'Ruby',
  readmeHtml:
    '<h1>Hello world</h1><div>This is my project markdown that is now html.<br /><pre>here is a code block</pre><br/><p>Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Dignissim sodales ut eu sem integer vitae. In metus vulputate eu scelerisque felis. Quis risus sed vulputate odio ut enim. Quis lectus nulla at volutpat diam ut venenatis tellus. Consectetur libero id faucibus nisl tincidunt. Leo a diam sollicitudin tempor. Elit ut aliquam purus sit amet luctus venenatis lectus magna. Tellus id interdum velit laoreet id. Bibendum est ultricies integer quis auctor elit sed vulputate. Eget egestas purus viverra accumsan in nisl nisi scelerisque eu. Faucibus scelerisque eleifend donec pretium vulputate sapien nec. Dignissim cras tincidunt lobortis feugiat vivamus at augue. Quam pellentesque nec nam aliquam sem et tortor. Ut tristique et egestas quis ipsum suspendisse ultrices gravida dictum. Tristique sollicitudin nibh sit amet. Eu tincidunt tortor aliquam nulla facilisi. Ac placerat vestibulum lectus mauris ultrices eros. A erat nam at lectus.</p><p>My second paragraph</p></div>',
  rootNamespace: { id: 1, fullPath: '/group/project', name: 'my-dumb-project' },
  statistics: {
    id: '1',
    forkCount: 2,
    starCount: 1,
    issues: 10,
    mergeRequests: 1,
  },
  versions: {
    id: 1,
    nodes: [{ id: 1, tagName: 'v1.0.2', releasedAt: '2022-08-23T17:19:09Z' }],
  },
};

export const cacheConfig = {
  cacheConfig: {
    typePolicies: {
      Query: {
        fields: {
          ciCatalogResources: {
            keyArgs: false,
          },
          ciCatalogResourcesDetails: {
            keyArgs: false,
            read() {
              return {
                nodes: [{ ...catalogDetailsMock }],
              };
            },
          },
        },
      },
    },
  },
};
