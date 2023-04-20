import {
  triggerExternalAlert,
  qualifiesForTasksToBeDone,
} from 'ee/invite_members/utils/member_utils';
import setWindowLocation from 'helpers/set_window_location_helper';
import { getParameterValues } from '~/lib/utils/url_utility';
import { LEARN_GITLAB } from 'ee/invite_members/constants';
import eventHub from '~/invite_members/event_hub';

jest.mock('~/lib/utils/url_utility');

describe('Trigger External Alert', () => {
  it.each([
    [LEARN_GITLAB, true],
    ['blah', false],
  ])(`returns result if it should trigger external alert: %j`, (value, result) => {
    jest.spyOn(eventHub, '$emit').mockImplementation();

    expect(triggerExternalAlert(value)).toBe(result);

    if (result) {
      expect(eventHub.$emit).toHaveBeenCalledWith('showSuccessfulInvitationsAlert');
    } else {
      expect(eventHub.$emit).not.toHaveBeenCalled();
    }
  });
});

describe('Qualifies For Tasks To Be Done', () => {
  it.each([
    ['invite_members_for_task', 'blah', true],
    ['blah', LEARN_GITLAB, true],
    ['blah', 'blah', false],
    ['invite_members_for_task', LEARN_GITLAB, true],
  ])(`returns result if it qualifies with url param: %j, source: %j`, (value, source, result) => {
    setWindowLocation(`blah/blah?open_modal=${value}`);
    getParameterValues.mockImplementation(() => {
      return [value];
    });

    expect(qualifiesForTasksToBeDone(source)).toBe(result);
  });
});
