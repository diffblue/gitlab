import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { isAbsolute, isSafeURL } from '~/lib/utils/url_utility';
import {
  REGEXES,
  SUPPORTED_IDENTIFIER_TYPE_CWE,
  SUPPORTED_IDENTIFIER_TYPE_OWASP,
} from './constants';

// Get the issue in the format expected by the descendant components of related_issues_block.vue.
export const getFormattedIssue = (issue) => ({
  ...issue,
  reference: `#${issue.iid}`,
  path: issue.web_url,
});

export const getAddRelatedIssueRequestParams = (reference, defaultProjectId) => {
  let issueId = reference;
  let projectId = defaultProjectId;

  // If the reference is an issue number, parse out just the issue number.
  if (REGEXES.ISSUE_FORMAT.test(reference)) {
    [, issueId] = REGEXES.ISSUE_FORMAT.exec(reference);
  }
  // If the reference is an absolute URL and matches the issues URL format, parse out the project and issue.
  else if (isSafeURL(reference) && isAbsolute(reference)) {
    const { pathname } = new URL(reference);

    if (REGEXES.LINK_FORMAT.test(pathname)) {
      [, projectId, issueId] = REGEXES.LINK_FORMAT.exec(pathname);
    }
  }

  return { target_issue_iid: issueId, target_project_id: projectId };
};

export const normalizeGraphQLNote = (note) => {
  if (!note) {
    return null;
  }

  return {
    ...note,
    id: getIdFromGraphQLId(note.id),
    author: {
      ...note.author,
      id: getIdFromGraphQLId(note.author.id),
      path: note.author.webPath,
    },
  };
};

export const normalizeGraphQLVulnerability = (vulnerability) => {
  if (!vulnerability) {
    return null;
  }

  const newVulnerability = { ...vulnerability };

  if (vulnerability.id) {
    newVulnerability.id = getIdFromGraphQLId(vulnerability.id);
  }

  if (vulnerability.state) {
    newVulnerability.state = vulnerability.state.toLowerCase();
  }

  ['confirmed', 'resolved', 'dismissed'].forEach((state) => {
    if (vulnerability[`${state}By`]?.id) {
      newVulnerability[`${state}ById`] = getIdFromGraphQLId(vulnerability[`${state}By`].id);
      delete newVulnerability[`${state}By`];
    }
  });

  return newVulnerability;
};

export const normalizeGraphQLLastStateTransition = (graphQLVulnerability, vulnerability) => {
  const stateTransitions = [...vulnerability.stateTransitions];

  // The vulnerability status mutation only returns 1 stateTransition
  const [graphQLLastStateTransitions] = graphQLVulnerability.stateTransitions.nodes;
  stateTransitions.push({
    ...graphQLLastStateTransitions,
    dismissalReason: graphQLLastStateTransitions.dismissalReason?.toLowerCase(),
  });

  return { stateTransitions };
};

export const formatIdentifierExternalIds = ({ externalType, externalId, name }) => {
  return `[${externalType}]-[${externalId}]-[${name}]`;
};

export const isSupportedIdentifier = (externalType) => {
  return (
    externalType?.toLowerCase() === SUPPORTED_IDENTIFIER_TYPE_CWE ||
    // Case matters here. owasp and OWASP require different configuration
    // Currently, our API only support lowercase owasp
    // Uppercase OWASP will be supported in a follow up issue:
    // https://gitlab.com/gitlab-org/gitlab/-/issues/366556
    externalType === SUPPORTED_IDENTIFIER_TYPE_OWASP
  );
};
