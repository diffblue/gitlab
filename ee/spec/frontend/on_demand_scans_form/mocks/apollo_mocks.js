import { scannerProfiles, siteProfiles } from './mock_data';

const defaults = {
  pageInfo: {
    hasNextPage: false,
    hasPreviousPage: false,
    startCursor: null,
    endCursor: null,
  },
};

export const dastScannerProfiles = (profiles = scannerProfiles) => ({
  data: {
    project: {
      id: '1',
      scannerProfiles: {
        ...defaults,
        edges: profiles.map((profile) => ({
          cursor: '',
          node: profile,
        })),
      },
    },
  },
});

export const dastSiteProfiles = (profiles = siteProfiles) => ({
  data: {
    project: {
      id: '1',
      siteProfiles: {
        ...defaults,
        edges: profiles.map((profile) => ({
          cursor: '',
          node: profile,
        })),
      },
    },
  },
});
