import { getBaseURL, joinPaths } from '~/lib/utils/url_utility';

export const getSourceUrl = (fullPath) => {
  return joinPaths(getBaseURL(), 'groups', fullPath, '-', 'security', 'policies');
};

export const isPolicyInherited = (source) => {
  if (source?.inherited === true) {
    return true;
  }

  return false;
};
