---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# HAML

[HAML](https://haml.info/) is the [Ruby on Rails](https://rubyonrails.org/) template that GitLab uses.

## GitLab UI form builder

[GitLab UI](https://gitlab-org.gitlab.io/gitlab-ui/) is a Vue component library that conforms to the [Pajamas design system](https://design.gitlab.com/). A lot of these components rely on JavaScript and therefore can only be used in Vue but some of the simpler components (checkboxes, radio buttons, form inputs) can be used in HAML by applying the correct CSS classes to the elements. A custom [Ruby on Rails form builder](https://gitlab.com/gitlab-org/gitlab/-/blob/7c108df101e86d8a27d69df2b5b1ff1fc24133c5/lib/gitlab/form_builders/gitlab_ui_form_builder.rb) exists to help use GitLab UI components in HAML.

### How to use the GitLab UI form builder

1. Change `form_for` to `gitlab_ui_form_for`
1. Change `f.check_box` to `f.gitlab_ui_checkbox_component`
1. Remove `f.label` and instead pass the label as the second argument in `f.gitlab_ui_checkbox_component`

**Before**

```haml
= gitlab_ui_form_for @group do |f|
  .form-group.gl-mb-3
    .gl-form-checkbox.custom-control.custom-checkbox
      = f.check_box :prevent_sharing_groups_outside_hierarchy, disabled: !can_change_prevent_sharing_groups_outside_hierarchy?(@group), class: 'custom-control-input'
      = f.label :prevent_sharing_groups_outside_hierarchy, class: 'custom-control-label' do
        %span
          = s_('GroupSettings|Prevent members from sending invitations to groups outside of %{group} and its subgroups.').html_safe % { group: link_to_group(@group) }
        %p.js-descr.help-text= prevent_sharing_groups_outside_hierarchy_help_text(@group)
```

**After**

```haml
= gitlab_ui_form_for @group do |f|
  .form-group
    = f.gitlab_ui_checkbox_component :prevent_sharing_groups_outside_hierarchy,
        s_('GroupSettings|Prevent members from sending invitations to groups outside of %{group} and its subgroups.').html_safe % { group: link_to_group(@group) },
        help_text: prevent_sharing_groups_outside_hierarchy_help_text(@group),
        checkbox_options: { disabled: !can_change_prevent_sharing_groups_outside_hierarchy?(@group) }
```

### Available components

#### gitlab_ui_checkbox_component

[GitLab UI Docs](https://gitlab-org.gitlab.io/gitlab-ui/?path=/story/base-form-form-checkbox--default)

| Argument | Description | Type | Required (default value) |
|---|---|---|---|
| `method` | Attribute on the object passed to `gitlab_ui_form_for`. | `Symbol` | `true` |
| `label` | Checkbox label. | `String` | `true` |
| `help_text` | Help text displayed below the checkbox. | `String` | `false` (`nil`) |
| `checkbox_options` | Options that are passed to [Rails `check_box` method](https://apidock.com/rails/ActionView/Helpers/FormHelper/check_box). | `Hash` | `false` (`{}`) |
| `label_options` | Options that are passed to [Rails `label` method](https://apidock.com/rails/ActionView/Helpers/FormHelper/label). | `Hash` | `false` (`{}`) |
