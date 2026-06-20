# MimooD App Blueprint

## Overview

This document outlines the plan and progress for the MimooD Flutter application. The app will serve as a mobile client for the MimooD WordPress portal, displaying posts and news in a clean, user-friendly interface.

## Style, Design, and Features (Version 1.0)

*   **Platform:** Flutter (iOS, Android, Web)
*   **Design:** Modern, visually appealing design using Material 3.
*   **Theming:** A consistent theme with a defined color scheme and typography.
*   **Core Feature:** Display posts and news from the MimooD WordPress site.
*   **Navigation:** A simple navigation flow between a list of posts and a detailed view of each post.

## Current Plan: Initial Setup

1.  **Create Blueprint:** Establish this `blueprint.md` file to track the project.
2.  **Add Dependencies:** Add necessary packages for HTTP requests (`http`), navigation (`go_router`), and rendering HTML content (`flutter_html`).
3.  **Basic Scaffolding:** Set up the initial app structure in `lib/main.dart` with a home screen.
4.  **Fetch & Display Posts:**
    *   Create a service to fetch data from the WordPress REST API.
    *   Create a model to represent a WordPress post.
    *   Implement a list view on the home screen to display post titles and excerpts.
5.  **Detail Screen:** Create a screen to show the full content of a selected post.
