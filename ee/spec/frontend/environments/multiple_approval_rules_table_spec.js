import { GlTableLite, GlAvatar, GlAvatarLink } from '@gitlab/ui';
import mockDeploymentFixture from 'test_fixtures/graphql/environments/graphql/queries/deployment.query.graphql.json';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import MultipleApprovalRulesTable from 'ee/environments/components/multiple_approval_rules_table.vue';
import { s__ } from '~/locale';

describe('ee/environments/components/multiple_approval_rules_table.vue', () => {
  let wrapper;
  const { rules } = mockDeploymentFixture.data.project.deployment.approvalSummary;

  const createWrapper = ({ propsData = {} } = {}) =>
    mountExtended(MultipleApprovalRulesTable, {
      propsData: { rules, ...propsData },
    });

  const findTable = () => wrapper.findComponent(GlTableLite);

  const findDataRows = () => {
    const table = findTable();
    // Drop Header Row
    const [, ...rows] = table.findAll('tr').wrappers;
    return rows;
  };

  describe('rules', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('should show a row for each rule', () => {
      const rows = findDataRows();

      expect(rows.length).toBe(rules.length);
    });

    it('should link to group via name', () => {
      const { name, webUrl } = rules.find((rule) => rule.group).group;

      const groupLink = wrapper.findByRole('link', { name });

      expect(groupLink.attributes('href')).toBe(webUrl);
    });

    it('should link user via name', () => {
      const { name, webUrl } = rules.find((rule) => rule.user).user;

      const userLink = wrapper.findByRole('link', { name });

      expect(userLink.attributes('href')).toBe(webUrl);
    });

    it('should show access level for maintainers', () => {
      const cell = wrapper.findByRole('cell', { name: s__('DeploymentApprovals|Maintainers') });
      expect(cell.exists()).toBe(true);
    });

    it('should show access level for developers', () => {
      const cell = wrapper.findByRole('cell', {
        name: s__('DeploymentApprovals|Developers + Maintainers'),
      });
      expect(cell.exists()).toBe(true);
    });

    it('should show number of approvals out of required approval count', () => {
      const cell = wrapper.findByRole('cell', { name: '1/1' });

      expect(cell.exists()).toBe(true);
    });

    it('should show an avatar for all approvals', () => {
      const avatars = wrapper.findAllComponents(GlAvatar);
      const avatarLinks = wrapper.findAllComponents(GlAvatarLink);
      const approvals = rules.flatMap((rule) => rule.approvals);

      approvals.forEach((approval, index) => {
        const avatar = avatars.wrappers[index];
        const avatarLink = avatarLinks.wrappers[index];
        const { user } = approval;

        expect(avatar.props('src')).toBe(user.avatarUrl);
        expect(avatarLink.attributes()).toMatchObject({
          href: user.webUrl,
          title: user.name,
        });
      });
    });
  });
});
