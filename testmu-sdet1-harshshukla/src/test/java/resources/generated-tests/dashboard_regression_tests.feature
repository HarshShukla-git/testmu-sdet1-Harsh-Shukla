# ============================================================
# Feature: Dashboard Module – Regression Test Suite
# Application: Web-Based Dashboard
# Author: Senior SDET
# Coverage: Widget Load, API Consistency, Failure Handling,
#           Filters/Sort, RBAC, Performance, Accessibility,
#           Responsive Design, Real-Time Data, Caching
# ============================================================

Feature: Dashboard Module Regression

  Background:
    Given the application is running and accessible
    And the backend REST APIs are available at base URL "https://api.dashboard.example.com"

  # ============================================================
  # 1. WIDGET LOAD VALIDATION
  # ============================================================

  @smoke @widget-load
  Scenario: All dashboard widgets load successfully on page load
    Given I am authenticated as "admin" user with valid session token
    When I navigate to the Dashboard page
    Then the "Sales Summary" widget should be visible within 3 seconds
    And the "Active Users" widget should be visible within 3 seconds
    And the "Notifications" widget should be visible within 3 seconds
    And each widget should display its title header
    And each widget should display a loading spinner while data is being fetched

  @widget-load
  Scenario: Widgets load independently without blocking each other
    Given I am authenticated as "admin" user
    And the API for "Sales Summary" responds in 2 seconds
    And the API for "Active Users" responds in 500 milliseconds
    When I navigate to the Dashboard page
    Then the "Active Users" widget should render data before "Sales Summary"
    And the "Notifications" widget should not wait for other widgets to complete

  @widget-load
  Scenario: Widget data matches mock API response on initial load
    Given I am authenticated as "admin" user
    And the "Sales Summary" API returns the following response:
      """
      {
        "totalSales": 152430,
        "currency": "USD",
        "growthPercent": 12.5,
        "period": "2026-02"
      }
      """
    When I navigate to the Dashboard page
    Then the "Sales Summary" widget should display total sales as "$152,430"
    And the "Sales Summary" widget should display growth as "+12.5%"
    And the "Sales Summary" widget should display the period as "Feb 2026"

  @widget-load
  Scenario: Active Users widget renders correct user count from API
    Given I am authenticated as "admin" user
    And the "Active Users" API returns:
      """
      { "activeCount": 3874, "trend": "up", "changePercent": 8.2 }
      """
    When I navigate to the Dashboard page
    Then the "Active Users" widget should display "3,874 Active Users"
    And the trend indicator should show an upward arrow
    And the change should display "+8.2%"

  @widget-load
  Scenario: Notifications widget renders unread notifications count
    Given I am authenticated as "admin" user
    And the "Notifications" API returns 5 unread notifications
    When I navigate to the Dashboard page
    Then the "Notifications" widget should display 5 unread items
    And the notification badge count should show "5"

  # ============================================================
  # 2. API DATA CONSISTENCY VALIDATION
  # ============================================================

  @api-consistency
  Scenario: Widget data is consistent with direct API response
    Given I am authenticated as "admin" user
    When I navigate to the Dashboard page
    And I capture the response from "GET /api/v1/sales-summary"
    Then the "Sales Summary" widget should display values matching the API response fields:
      | Field          | API Key        |
      | Total Sales    | totalSales     |
      | Growth %       | growthPercent  |
      | Reporting Period | period       |

  @api-consistency
  Scenario: Dashboard data reflects API update after forced refresh
    Given I am authenticated as "admin" user
    And the "Sales Summary" API initially returns totalSales as "100000"
    When I navigate to the Dashboard page
    And the backend updates totalSales to "125000"
    And I trigger a manual dashboard refresh
    Then the "Sales Summary" widget should display "$125,000"

  @api-consistency
  Scenario: Timestamp shown in widget matches API response timestamp
    Given I am authenticated as "admin" user
    And the "Active Users" API returns lastUpdated as "2026-02-27T14:00:00Z"
    When I navigate to the Dashboard page
    Then the "Active Users" widget footer should display "Last updated: Feb 27, 2026 14:00 UTC"

  # ============================================================
  # 3. PARTIAL WIDGET FAILURE HANDLING
  # ============================================================

  @failure-handling
  Scenario: Dashboard renders successfully when one widget API fails
    Given I am authenticated as "admin" user
    And the "Sales Summary" API returns HTTP 500
    And the "Active Users" API returns a valid response
    And the "Notifications" API returns a valid response
    When I navigate to the Dashboard page
    Then the "Active Users" widget should display data correctly
    And the "Notifications" widget should display data correctly
    And the "Sales Summary" widget should display an error state message "Unable to load Sales Summary"
    And a retry button should be visible in the "Sales Summary" widget

  @failure-handling
  Scenario: Clicking retry on a failed widget re-fetches its data
    Given I am authenticated as "admin" user
    And the "Sales Summary" API initially returns HTTP 500
    When I navigate to the Dashboard page
    And the "Sales Summary" widget displays an error state
    And the "Sales Summary" API now returns a valid response
    And I click the "Retry" button in the "Sales Summary" widget
    Then the "Sales Summary" widget should display the correct data
    And the error state should no longer be visible

  @failure-handling
  Scenario: Network timeout on a single widget shows timeout message
    Given I am authenticated as "admin" user
    And the "Notifications" API does not respond within 10 seconds
    When I navigate to the Dashboard page
    Then the "Notifications" widget should display "Request timed out. Please try again."
    And the other widgets should not be affected

  @failure-handling
  Scenario: All widgets fail simultaneously and dashboard shows global error
    Given I am authenticated as "admin" user
    And all widget APIs return HTTP 503
    When I navigate to the Dashboard page
    Then each widget should display individual error messages
    And a global notification banner should read "Some dashboard data is unavailable. Please refresh."

  # ============================================================
  # 4. EMPTY STATE HANDLING
  # ============================================================

  @empty-state
  Scenario: Sales Summary widget shows empty state when API returns no data
    Given I am authenticated as "admin" user
    And the "Sales Summary" API returns:
      """
      { "totalSales": 0, "growthPercent": 0, "period": "2026-02" }
      """
    When I navigate to the Dashboard page
    Then the "Sales Summary" widget should display "No sales data available for the selected period"
    And no chart or figure should be rendered in the widget

  @empty-state
  Scenario: Active Users widget shows empty state when zero active users
    Given I am authenticated as "admin" user
    And the "Active Users" API returns activeCount as 0
    When I navigate to the Dashboard page
    Then the "Active Users" widget should display "No active users currently"

  @empty-state
  Scenario: Notifications widget shows empty state when no notifications exist
    Given I am authenticated as "admin" user
    And the "Notifications" API returns an empty array
    When I navigate to the Dashboard page
    Then the "Notifications" widget should display "You have no new notifications"
    And the notification badge should not be visible

  # ============================================================
  # 5. FILTER AND SORT CORRECTNESS
  # ============================================================

  @filter-sort
  Scenario: Filtering Sales Summary by date range returns correct data
    Given I am authenticated as "admin" user
    When I navigate to the Dashboard page
    And I apply a date range filter from "2026-01-01" to "2026-01-31" on "Sales Summary"
    Then the API call to "/api/v1/sales-summary" should include query params "startDate=2026-01-01&endDate=2026-01-31"
    And the "Sales Summary" widget should update to display January 2026 data

  @filter-sort
  Scenario: Sorting Notifications by date descending shows newest first
    Given I am authenticated as "admin" user
    And the "Notifications" API returns 3 notifications with dates:
      | id | date       |
      | 1  | 2026-02-25 |
      | 2  | 2026-02-27 |
      | 3  | 2026-02-20 |
    When I navigate to the Dashboard page
    And I sort notifications by "Date: Newest First"
    Then the notifications should display in order: id 2, id 1, id 3

  @filter-sort
  Scenario: Filtering Active Users by region updates widget data
    Given I am authenticated as "admin" user
    When I navigate to the Dashboard page
    And I apply the region filter "North America" on the "Active Users" widget
    Then the API call to "/api/v1/active-users" should include "region=NorthAmerica"
    And the "Active Users" widget should display the filtered count

  @filter-sort
  Scenario: Clearing applied filters restores original widget data
    Given I am authenticated as "admin" user
    And I have applied a date filter on "Sales Summary"
    When I click "Clear Filters"
    Then the "Sales Summary" widget should reload with unfiltered API data
    And the filter input fields should be reset to default values

  @filter-sort
  Scenario: Invalid filter input displays validation error
    Given I am authenticated as "admin" user
    When I navigate to the Dashboard page
    And I set the filter start date to "2026-02-28" and end date to "2026-01-01"
    Then a validation error should appear: "Start date must be before end date"
    And no API call should be made with the invalid date range

  # ============================================================
  # 6. ROLE-BASED VISIBILITY VALIDATION
  # ============================================================

  @rbac
  Scenario: Admin user sees all dashboard widgets
    Given I am authenticated as "admin" user
    When I navigate to the Dashboard page
    Then I should see the "Sales Summary" widget
    And I should see the "Active Users" widget
    And I should see the "Notifications" widget
    And I should see the "Export Data" button

  @rbac
  Scenario: Standard user does not see Sales Summary widget
    Given I am authenticated as "standard" user
    When I navigate to the Dashboard page
    Then I should NOT see the "Sales Summary" widget
    And I should see the "Active Users" widget
    And I should see the "Notifications" widget
    And I should NOT see the "Export Data" button

  @rbac
  Scenario: Standard user cannot access admin-only API endpoint directly
    Given I am authenticated as "standard" user with a valid session token
    When I send a GET request to "/api/v1/admin/sales-summary"
    Then the response status code should be 403
    And the response body should contain "Access denied: insufficient permissions"

  @rbac
  Scenario: Role-specific widgets are determined server-side not client-side
    Given I am authenticated as "standard" user
    When I manipulate the DOM to inject the "Sales Summary" widget
    And I trigger the widget's data-fetch call to "/api/v1/sales-summary"
    Then the API response status should be 403
    And the widget should not render any meaningful data

  # ============================================================
  # 7. UNAUTHORIZED ACCESS PREVENTION
  # ============================================================

  @auth
  Scenario: Unauthenticated user is redirected to login page
    Given I am not logged in
    When I navigate to the Dashboard page URL directly
    Then I should be redirected to "/login"
    And the login page should display "Please sign in to continue"

  @auth
  Scenario: Expired session token redirects user to login
    Given I am authenticated with an expired session token
    When I navigate to the Dashboard page
    Then I should be redirected to "/login"
    And the login page should display "Your session has expired. Please log in again."

  @auth
  Scenario: Dashboard APIs return 401 for requests without a valid token
    Given no authorization header is present in the request
    When I send a GET request to "/api/v1/sales-summary"
    Then the response status code should be 401
    And the response body should contain "Unauthorized"

  @auth
  Scenario: Tampered JWT token is rejected by the API
    Given I have a valid session but I tamper the JWT payload to elevate my role to "admin"
    When I send a GET request to "/api/v1/admin/sales-summary" with the tampered token
    Then the response status code should be 401
    And the response body should contain "Invalid token signature"

  # ============================================================
  # 8. SLOW API RESPONSE HANDLING
  # ============================================================

  @performance @slow-api
  Scenario: Dashboard shows loading skeleton while APIs are slow
    Given I am authenticated as "admin" user
    And all widget APIs have a simulated delay of 4 seconds
    When I navigate to the Dashboard page
    Then each widget should display a skeleton loading placeholder within 500 milliseconds
    And the skeleton should be replaced with data once the API responds

  @performance @slow-api
  Scenario: Dashboard remains interactive while a single widget is still loading
    Given I am authenticated as "admin" user
    And the "Sales Summary" API has a simulated delay of 5 seconds
    And the other widget APIs respond immediately
    When I navigate to the Dashboard page
    Then the "Active Users" and "Notifications" widgets should be interactive
    And I should be able to apply filters while "Sales Summary" is still loading

  @performance @slow-api
  Scenario: Widget displays timeout error if API exceeds 10 seconds
    Given I am authenticated as "admin" user
    And the "Active Users" API does not respond for 11 seconds
    When I navigate to the Dashboard page
    Then the "Active Users" widget should display "Data could not be loaded. Please try again."
    After 10 seconds from page load

  # ============================================================
  # 9. RESPONSIVE LAYOUT VALIDATION
  # ============================================================

  @responsive
  Scenario Outline: Dashboard layout renders correctly at different viewport sizes
    Given I am authenticated as "admin" user
    When I set the browser viewport to <width> x <height>
    And I navigate to the Dashboard page
    Then all widgets should be visible without horizontal scrolling
    And the layout should match the expected <layout> configuration
    And no widget content should be clipped or overflowing

    Examples:
      | width | height | layout            |
      | 1440  | 900    | 3-column grid     |
      | 768   | 1024   | 2-column grid     |
      | 375   | 812    | single-column     |

  @responsive
  Scenario: Navigation menu collapses into hamburger on mobile viewport
    Given I am authenticated as "admin" user
    When I set the browser viewport to 375 x 812
    And I navigate to the Dashboard page
    Then the main navigation should display as a hamburger menu icon
    And the dashboard widgets should stack vertically in a single column

  @responsive
  Scenario: Widget charts are legible and touch-friendly on mobile
    Given I am authenticated as "admin" user
    And I set the browser viewport to 375 x 812
    When I navigate to the Dashboard page
    Then each widget chart element should have a minimum touch target of 44x44 pixels
    And text within widgets should meet a minimum font size of 14px

  # ============================================================
  # 10. REAL-TIME DATA REFRESH BEHAVIOR
  # ============================================================

  @real-time
  Scenario: Active Users widget auto-refreshes at configured interval
    Given I am authenticated as "admin" user
    And the real-time refresh interval is configured to 30 seconds
    When I navigate to the Dashboard page
    And 30 seconds elapse
    Then the "Active Users" API should be called again automatically
    And the "Active Users" widget should display updated data without a page reload

  @real-time
  Scenario: Widget updates data in real-time via WebSocket push
    Given I am authenticated as "admin" user
    And the "Active Users" widget is connected via WebSocket
    When the server pushes a new message: { "activeCount": 4200 }
    Then the "Active Users" widget should update to display "4,200 Active Users" within 1 second
    And no full page reload should occur

  @real-time
  Scenario: Real-time updates are paused when the browser tab is inactive
    Given I am authenticated as "admin" user
    And real-time polling is active on the Dashboard
    When I switch to a different browser tab
    Then polling API calls should be suspended
    When I return to the Dashboard tab
    Then polling should resume and the widget should refresh immediately

  @real-time
  Scenario: Brief notification appears when real-time data is updated
    Given I am authenticated as "admin" user
    And the "Active Users" widget receives a real-time data push
    When the widget updates its displayed data
    Then a subtle "Live" indicator badge should be visible on the widget for 3 seconds

  # ============================================================
  # 11. CACHING BEHAVIOR VALIDATION
  # ============================================================

  @caching
  Scenario: Dashboard serves cached data on subsequent load within TTL window
    Given I am authenticated as "admin" user
    And the "Sales Summary" API has a cache TTL of 60 seconds
    When I navigate to the Dashboard page
    And the "Sales Summary" data is loaded and cached
    And I navigate away and return to the Dashboard within 60 seconds
    Then the "Sales Summary" widget should load immediately from cache
    And no new API call should be made to "/api/v1/sales-summary"

  @caching
  Scenario: Cache is invalidated after TTL expires and fresh data is fetched
    Given I am authenticated as "admin" user
    And the cached "Sales Summary" data has expired
    When I navigate to the Dashboard page
    Then a new API call should be made to "/api/v1/sales-summary"
    And the widget should display the fresh API response

  @caching
  Scenario: Forced refresh bypasses cache and fetches fresh data
    Given I am authenticated as "admin" user
    And the "Sales Summary" widget has cached data
    When I click the "Refresh" button on the Dashboard
    Then an API call should be made to "/api/v1/sales-summary" with cache bypass headers
    And the widget should display the updated API response

  @caching
  Scenario: Different user roles do not share cached widget data
    Given "admin" user has previously loaded the Dashboard and cached data is stored
    When "standard" user navigates to the Dashboard page
    Then the "standard" user's widget requests should not use the "admin" user's cached data
    And the API should be called with "standard" user credentials

  # ============================================================
  # 12. ERROR MESSAGE VALIDATION
  # ============================================================

  @error-messages
  Scenario: HTTP 400 from API displays user-friendly validation error
    Given I am authenticated as "admin" user
    And the filter API returns HTTP 400 with:
      """
      { "error": "invalid_date_format", "message": "Date must be in YYYY-MM-DD format" }
      """
    When I apply an incorrectly formatted date filter
    Then the widget should display "Invalid input. Please use YYYY-MM-DD format."
    And the raw API error code "invalid_date_format" should NOT be visible to the user

  @error-messages
  Scenario: HTTP 500 from API displays generic server error message
    Given I am authenticated as "admin" user
    And the "Notifications" API returns HTTP 500
    When I navigate to the Dashboard page
    Then the "Notifications" widget should display "Something went wrong. Please try again later."

  @error-messages
  Scenario: HTTP 503 from API displays service unavailability message
    Given I am authenticated as "admin" user
    And the "Active Users" API returns HTTP 503
    When I navigate to the Dashboard page
    Then the "Active Users" widget should display "Service temporarily unavailable. Please check back shortly."

  @error-messages
  Scenario: Network disconnection shows offline error with reconnect option
    Given I am authenticated as "admin" user
    And I am on the Dashboard page
    When network connectivity is lost
    Then a banner should appear: "You are offline. Some data may be outdated."
    And a "Reconnect" button should be visible
    When network connectivity is restored and I click "Reconnect"
    Then all widgets should refresh with the latest data

  # ============================================================
  # 13. ACCESSIBILITY CHECKS
  # ============================================================

  @accessibility
  Scenario: Dashboard page has a valid ARIA landmark structure
    Given I am authenticated as "admin" user
    When I navigate to the Dashboard page
    Then the page should contain a <main> landmark with role "main"
    And each widget should be wrapped in an element with role "region"
    And each widget region should have a unique aria-label attribute

  @accessibility
  Scenario: All interactive widget controls are keyboard navigable
    Given I am authenticated as "admin" user
    When I navigate to the Dashboard page
    And I press the Tab key to cycle through interactive elements
    Then focus should move in logical order through filter inputs, sort dropdowns, and buttons
    And each focused element should display a visible focus outline

  @accessibility
  Scenario: Loading spinner has an appropriate ARIA label for screen readers
    Given I am authenticated as "admin" user
    And a widget API is loading
    When I inspect the loading spinner element
    Then it should have aria-label="Loading data, please wait"
    And the spinner should have role="status"

  @accessibility
  Scenario: Error state messages are announced by screen readers
    Given I am authenticated as "admin" user
    And a widget API returns a failure
    When the error message is rendered in the widget
    Then the error container should have role="alert"
    And aria-live should be set to "assertive"

  @accessibility
  Scenario: Dashboard color contrast meets WCAG 2.1 AA standards
    Given I am authenticated as "admin" user
    When I navigate to the Dashboard page
    Then all text elements should have a minimum contrast ratio of 4.5:1 against their background
    And interactive elements such as buttons should have a minimum contrast ratio of 3:1

  @accessibility
  Scenario: Images and icons in widgets have descriptive alt text
    Given I am authenticated as "admin" user
    When I navigate to the Dashboard page
    Then all non-decorative images and icons should have a non-empty alt attribute
    And decorative icons should have aria-hidden="true"

  # ============================================================
  # 14. PERFORMANCE THRESHOLD VALIDATION
  # ============================================================

  @performance
  Scenario: Dashboard page loads fully within 3 seconds under normal conditions
    Given I am authenticated as "admin" user
    And the network condition is "fast 3G" or better
    When I navigate to the Dashboard page
    Then the page should reach "interactive" state within 3 seconds
    And all above-the-fold widget content should be visible within 3 seconds

  @performance
  Scenario: Dashboard Time to First Byte (TTFB) is under 600 milliseconds
    Given I am authenticated as "admin" user
    When I navigate to the Dashboard page
    Then the Time to First Byte should be less than 600 milliseconds

  @performance
  Scenario: Largest Contentful Paint (LCP) is under 2.5 seconds
    Given I am authenticated as "admin" user
    When I navigate to the Dashboard page
    Then the Largest Contentful Paint metric should be less than 2500 milliseconds

  @performance
  Scenario: Cumulative Layout Shift (CLS) is within acceptable threshold
    Given I am authenticated as "admin" user
    When I navigate to the Dashboard page and all widgets finish loading
    Then the Cumulative Layout Shift score should be less than 0.1
    And widgets should not cause visible content jumps when loaded

  @performance
  Scenario: Dashboard remains performant with maximum widget data volume
    Given I am authenticated as "admin" user
    And the "Notifications" API returns 500 notification records
    When I navigate to the Dashboard page
    Then the page should still reach interactive state within 3 seconds
    And the browser should not freeze or become unresponsive during render

  @performance
  Scenario: Widget re-render on filter change completes within 1 second
    Given I am authenticated as "admin" user
    And I am on the Dashboard page with all widgets loaded
    When I apply a date range filter on the "Sales Summary" widget
    Then the widget should display updated results within 1 second of the API response
