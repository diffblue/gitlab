<script>
import CEMembersTableCell from '~/members/components/table/members_table_cell.vue';
import { MEMBER_TYPES } from 'ee_else_ce/members/constants';
import { canOverride } from '../../utils';

export default {
  name: 'MembersTableCell',
  props: {
    member: {
      type: Object,
      required: true,
    },
  },
  computed: {
    canOverride() {
      return canOverride(this.member);
    },
  },
  methods: {
    memberType(ceMemberType) {
      if (this.member.banned) {
        return MEMBER_TYPES.banned;
      }

      return ceMemberType;
    },
  },
  render(createElement) {
    return createElement(CEMembersTableCell, {
      props: { member: this.member },
      scopedSlots: {
        default: (props) => {
          return this.$scopedSlots.default({
            ...props,
            memberType: this.memberType(props.memberType),
            permissions: {
              ...props.permissions,
              canOverride: this.canOverride,
            },
          });
        },
      },
    });
  },
};
</script>
