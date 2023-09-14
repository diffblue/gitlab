import eventHub from '~/invite_members/event_hub';
import { LEARN_GITLAB } from '../constants';

export { memberName } from '~/invite_members/utils/member_utils';

function isOnLearnGitlab(source) {
  return source === LEARN_GITLAB;
}

export function triggerExternalAlert(source) {
  if (isOnLearnGitlab(source)) {
    eventHub.$emit('showSuccessfulInvitationsAlert');
    return true;
  }

  return false;
}
