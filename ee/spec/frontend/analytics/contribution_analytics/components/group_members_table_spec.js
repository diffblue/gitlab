import { mount } from '@vue/test-utils';
import { GlTable, GlLink } from '@gitlab/ui';
import { nextTick } from 'vue';
import GroupMembersTable from 'ee/analytics/contribution_analytics/components/group_members_table.vue';
import { TABLE_COLUMNS } from 'ee/analytics/contribution_analytics/constants';
import { MOCK_CONTRIBUTIONS } from '../mock_data';

describe('GroupMembersTable', () => {
  let wrapper;

  const createWrapper = () => {
    wrapper = mount(GroupMembersTable, {
      propsData: {
        contributions: MOCK_CONTRIBUTIONS,
      },
    });
  };

  const findTable = () => wrapper.findComponent(GlTable);
  const findHeaders = () => findTable().findAll('th');
  const findRows = () => findTable().find('tbody').findAll('tr');

  describe('table headings', () => {
    let headers;
    let index = 0;

    beforeEach(() => {
      createWrapper();
      headers = findHeaders();
    });

    it('displays the correct number of headings', () => {
      expect(headers).toHaveLength(TABLE_COLUMNS.length);
    });

    describe.each(TABLE_COLUMNS)('header fields', ({ label }) => {
      let headerWrapper;

      beforeEach(() => {
        headerWrapper = headers.at(index);
        index += 1;
      });

      it(`displays the correct table heading text for "${label}"`, () => {
        expect(headerWrapper.text()).toContain(label);
      });
    });
  });

  describe('table rows', () => {
    let rows;
    let index = 0;

    beforeEach(() => {
      createWrapper();
      rows = findRows();
    });

    it('displays the correct number of rows', () => {
      expect(rows).toHaveLength(MOCK_CONTRIBUTIONS.length);
    });

    describe.each(MOCK_CONTRIBUTIONS)('rows', ({ user: { name, webUrl } }) => {
      let rowWrapper;

      beforeEach(() => {
        rowWrapper = rows.at(index);
        index += 1;
      });

      it(`displays the correct content for "${name}"`, () => {
        expect(rowWrapper.text()).toContain(name);
        expect(rowWrapper.findComponent(GlLink).attributes('href')).toBe(webUrl);
      });
    });
  });

  describe('sorting', () => {
    let headers;
    let rows;

    beforeEach(() => {
      createWrapper();
      headers = findHeaders();
      rows = findRows();
    });

    it('sorts by name', async () => {
      expect(rows.at(0).text()).toContain(MOCK_CONTRIBUTIONS[0].user.name);

      headers.at(0).trigger('click');

      await nextTick();

      expect(rows.at(0).text()).toContain(MOCK_CONTRIBUTIONS[2].user.name);
    });
  });
});
