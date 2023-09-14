import { triggerExternalAlert } from 'ee/invite_members/utils/member_utils';
import { LEARN_GITLAB } from 'ee/invite_members/constants';
import eventHub from '~/invite_members/event_hub';

jest.mock('~/lib/utils/url_utility');

describe('Trigger External Alert', () => {
  it.each([
    [LEARN_GITLAB, true],
    ['blah', false],
  ])(`returns result if it should trigger external alert: %j`, (source, result) => {
    jest.spyOn(eventHub, '$emit').mockImplementation();

    expect(triggerExternalAlert(source)).toBe(result);

    if (result) {
      expect(eventHub.$emit).toHaveBeenCalledWith('showSuccessfulInvitationsAlert');
    } else {
      expect(eventHub.$emit).not.toHaveBeenCalled();
    }
  });
});
