import { EMPTY_BODY_MESSAGE } from './constants';

/**
 * A helper function which validates the passed
 * in body string.
 *
 * It returns an empty string if the body has explicitly
 * been passed in as an empty string, a fallback
 * message if the body is null / undefined, else
 * it will return the original body string.
 *
 * @param {String} body the body message
 *
 * @return {String} the validated body message
 */
export const bodyWithFallBack = (body) => (body === '' ? '' : body || EMPTY_BODY_MESSAGE);

export const getCreatedIssueForVulnerability = (vulnerability) =>
  vulnerability.issue_links?.find((link) => link.link_type === 'created');

export const getDismissalTransitionForVulnerability = (vulnerability) => {
  const latestTransition = vulnerability.state_transitions?.at(-1);
  return latestTransition?.to_state.toLowerCase() === 'dismissed' ? latestTransition : null;
};
