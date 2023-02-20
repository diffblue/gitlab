---
stage: Manage
group: Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Sidebar

Follow these guidelines when contributing additions or changes to the
[redesigned](https://gitlab.com/groups/gitlab-org/-/epics/9044) navigation
sidebar.

To enable the new navigation, enable the `super_sidebar_nav` feature flag, then
click the **New navigation** toggle in your user menu.

This is a living document as the sidebar is being actively developed.

## Adding page-specific Vue content

Pages can render arbitrary content into the sidebar using the `SidebarPortal`
component. Content passed to its default slot will be rendered below that
page's nav items in the sidebar.

NOTE:
Only one instance of this component on a given page is supported. This is to
avoid ordering issues and cluttering the sidebar.

NOTE:
Arbitrary content is allowed, but nav items should be implemented by
subclassing `::Sidebars::Panel`.

NOTE:
Do not use the `SidebarPortalTarget` component. It is internal to the sidebar.
