import { DEFAULT_GROUP_PATH } from 'ee/registrations/groups_projects/new/constants';
import createState from 'ee/registrations/groups_projects/new/store/state';

describe('State', () => {
  it('creates default state', () => {
    expect(createState()).toEqual({
      storeGroupName: '',
      storeGroupPath: DEFAULT_GROUP_PATH,
    });
  });
});
