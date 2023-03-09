import { shallowMount } from '@vue/test-utils';
import MemberToken from 'ee/audit_events/components/tokens/member_token.vue';
import AuditFilterToken from 'ee/audit_events/components/tokens/shared/audit_filter_token.vue';
import Api from '~/api';
import { getUsers } from '~/rest_api';
import { displayUsername, isValidUsername } from 'ee/audit_events/token_utils';

jest.mock('~/api.js', () => ({
  groupMembers: jest.fn().mockResolvedValue({ data: ['foo'] }),
  projectUsers: jest.fn().mockResolvedValue(['bar']),
}));

jest.mock('~/rest_api', () => ({
  getUsers: jest.fn().mockResolvedValue({
    data: [{ id: 1, name: 'user' }],
  }),
}));

jest.mock('ee/audit_events/token_utils', () => ({
  parseUsername: jest.requireActual('ee/audit_events/token_utils').parseUsername,
  displayUsername: jest.fn().mockImplementation((val) => val),
  isValidUsername: jest.fn().mockReturnValue(true),
}));

describe('MemberToken', () => {
  let wrapper;

  const value = { data: 123 };
  const config = { type: 'foo', groupId: 123 };

  const findAuditFilterToken = () => wrapper.findComponent(AuditFilterToken);

  const initComponent = () => {
    wrapper = shallowMount(MemberToken, {
      propsData: {
        value,
        config,
        active: false,
        cursorPosition: 'start',
      },
      stubs: { AuditFilterToken },
    });
  };

  beforeEach(() => {
    initComponent();
  });

  afterEach(() => {
    Api.groupMembers.mockClear();
    Api.projectUsers.mockClear();
  });

  it('binds to value, config and token methods to the filter token', () => {
    expect(findAuditFilterToken().props()).toMatchObject({
      value,
      config,
      ...wrapper.vm.$options.tokenMethods,
    });
  });

  describe('tokenMethods', () => {
    it('fetchItem', async () => {
      const subject = wrapper.vm.$options.tokenMethods.fetchItem;
      const username = 'term';

      const result = await subject(username);

      expect(result).toEqual({ id: 1, name: 'user' });
      expect(getUsers).toHaveBeenCalledWith('', { username, per_page: 1 });
    });

    it('fetchSuggestions - on group level', async () => {
      const context = { config: { groupId: 999 } };
      const subject = wrapper.vm.$options.tokenMethods.fetchSuggestions;
      const username = 'term';

      const result = await subject.call(context, username);

      expect(result).toEqual(['foo']);
      expect(Api.groupMembers).toHaveBeenCalledWith(999, { query: username });
    });

    it('fetchSuggestions - on project level', async () => {
      const context = { config: { projectPath: 'path' } };
      const subject = wrapper.vm.$options.tokenMethods.fetchSuggestions;
      const username = 'term';

      const result = await subject.call(context, username);

      expect(result).toEqual(['bar']);
      expect(Api.projectUsers).toHaveBeenCalledWith('path', username);
    });

    it('getItemName', () => {
      const subject = wrapper.vm.$options.tokenMethods.getItemName;
      const name = 'foo';

      expect(subject({ name })).toBe(name);
    });

    it('getSuggestionValue', () => {
      const subject = wrapper.vm.$options.tokenMethods.getSuggestionValue;
      const username = 'foo';

      expect(subject({ username })).toBe(username);
      expect(displayUsername).toHaveBeenCalledWith(username);
    });

    it('isValidIdentifier', () => {
      const subject = wrapper.vm.$options.tokenMethods.isValidIdentifier;

      expect(subject('foo')).toBe(true);
      expect(isValidUsername).toHaveBeenCalledWith('foo');
    });

    it('findActiveItem', () => {
      const subject = wrapper.vm.$options.tokenMethods.findActiveItem;
      const suggestions = [
        { id: 1, username: 'foo' },
        { id: 2, username: 'bar' },
      ];

      expect(subject(suggestions, 'foo')).toBe(suggestions[0]);
    });
  });
});
