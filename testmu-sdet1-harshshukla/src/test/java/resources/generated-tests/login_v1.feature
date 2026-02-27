# =============================================================================
# Feature: Login Module - Regression Test Suite
# Author  : SDET (Senior)
# Version : 1.0.0
# Date    : 2026-02-27
# =============================================================================

Feature: Login Module - Comprehensive Regression Coverage
  As a registered user of the application,
  I want to authenticate securely using my email and password,
  So that I can access my account and protected resources.

  Background:
    Given the application login page is loaded
    And the database contains a registered user with email "testuser@example.com" and password "Test@12345"

# =============================================================================
# SECTION 1 — Positive Login Scenarios
# =============================================================================

  @positive @smoke
  Scenario: Successful login with valid credentials
    Given the user is on the login page
    When the user enters email "testuser@example.com" and password "Test@12345"
    And the user clicks the "Login" button
    Then the user should be redirected to the dashboard
    And a valid JWT token should be present in the session storage
    And the token should contain the correct user claims

  @positive @smoke
  Scenario: Successful login with email containing uppercase characters (case-insensitive)
    Given the user is on the login page
    When the user enters email "TestUser@EXAMPLE.COM" and password "Test@12345"
    And the user clicks the "Login" button
    Then the user should be redirected to the dashboard
    And the system should normalise the email to lowercase before processing

  @positive
  Scenario: Login page remember me — session persists across browser restart
    Given the user is on the login page
    When the user enters email "testuser@example.com" and password "Test@12345"
    And the user checks the "Remember Me" checkbox
    And the user clicks the "Login" button
    Then the user should be redirected to the dashboard
    And the persistent session cookie should be set with the correct expiry

  @positive
  Scenario: Successful login after a previously failed attempt
    Given the user is on the login page
    And the user has 1 failed login attempt recorded for "testuser@example.com"
    When the user enters email "testuser@example.com" and password "Test@12345"
    And the user clicks the "Login" button
    Then the user should be redirected to the dashboard
    And the failed attempt counter for "testuser@example.com" should be reset to 0

  @positive
  Scenario: Successful login redirects to originally requested protected page
    Given the user tries to access the protected URL "/dashboard/reports"
    And the user is redirected to the login page
    When the user enters email "testuser@example.com" and password "Test@12345"
    And the user clicks the "Login" button
    Then the user should be redirected to "/dashboard/reports"

# =============================================================================
# SECTION 2 — Invalid Credentials
# =============================================================================

  @negative
  Scenario: Login fails with correct email but wrong password
    Given the user is on the login page
    When the user enters email "testuser@example.com" and password "WrongPass@99"
    And the user clicks the "Login" button
    Then the user should remain on the login page
    And the error message "Invalid email or password." should be displayed
    And no JWT token should be issued

  @negative
  Scenario: Login fails with unregistered email
    Given the user is on the login page
    When the user enters email "ghost@example.com" and password "Test@12345"
    And the user clicks the "Login" button
    Then the user should remain on the login page
    And the error message "Invalid email or password." should be displayed

  @negative
  Scenario: Login fails with correct password but wrong email domain
    Given the user is on the login page
    When the user enters email "testuser@wrongdomain.com" and password "Test@12345"
    And the user clicks the "Login" button
    Then the user should remain on the login page
    And the error message "Invalid email or password." should be displayed

  @negative
  Scenario: Error message is generic and does not reveal whether email exists (no user enumeration)
    Given the user is on the login page
    When the user enters email "nonexistent@example.com" and password "AnyPassword@1"
    And the user clicks the "Login" button
    Then the error message should be "Invalid email or password."
    And the response time should not differ significantly from a valid email attempt

# =============================================================================
# SECTION 3 — Empty Fields and Boundary Values
# =============================================================================

  @negative @boundary
  Scenario: Login fails when both email and password fields are empty
    Given the user is on the login page
    When the user submits the login form without entering any credentials
    Then the field validation error "Email is required." should be displayed
    And the field validation error "Password is required." should be displayed
    And no HTTP request should be sent to the authentication endpoint

  @negative @boundary
  Scenario: Login fails when email field is empty
    Given the user is on the login page
    When the user enters password "Test@12345" and leaves the email field blank
    And the user clicks the "Login" button
    Then the field validation error "Email is required." should be displayed

  @negative @boundary
  Scenario: Login fails when password field is empty
    Given the user is on the login page
    When the user enters email "testuser@example.com" and leaves the password field blank
    And the user clicks the "Login" button
    Then the field validation error "Password is required." should be displayed

  @negative @boundary
  Scenario Outline: Login fails for invalid email formats
    Given the user is on the login page
    When the user enters email "<invalid_email>" and password "Test@12345"
    And the user clicks the "Login" button
    Then the field validation error "Please enter a valid email address." should be displayed

    Examples:
      | invalid_email         |
      | plainaddress          |
      | @missinglocal.org     |
      | user@                 |
      | user@.com             |
      | user@domain..com      |
      | user @example.com     |
      | user@exa mple.com     |

  @negative @boundary
  Scenario: Login fails when email exceeds maximum length (255 characters)
    Given the user is on the login page
    When the user enters an email of 256 characters and password "Test@12345"
    And the user clicks the "Login" button
    Then the field validation error "Email must not exceed 255 characters." should be displayed

  @negative @boundary
  Scenario: Login fails when password exceeds maximum length (128 characters)
    Given the user is on the login page
    When the user enters email "testuser@example.com" and a password of 129 characters
    And the user clicks the "Login" button
    Then the system should return an appropriate validation error

  @negative @boundary
  Scenario: Password field with only whitespace characters is rejected
    Given the user is on the login page
    When the user enters email "testuser@example.com" and password "          "
    And the user clicks the "Login" button
    Then the field validation error "Password is required." should be displayed

# =============================================================================
# SECTION 4 — SQL Injection Attempts
# =============================================================================

  @security @sql-injection
  Scenario Outline: SQL injection payloads in the email field are rejected
    Given the user is on the login page
    When the user enters email "<sql_payload>" and password "Test@12345"
    And the user clicks the "Login" button
    Then the login should fail with an appropriate error message
    And no SQL error or stack trace should be visible in the response
    And the database should remain unaffected

    Examples:
      | sql_payload                              |
      | ' OR '1'='1                              |
      | ' OR '1'='1' --                          |
      | admin'--                                 |
      | ' OR 1=1--                               |
      | '; DROP TABLE users; --                  |
      | ' UNION SELECT null, username, password FROM users -- |
      | 1' AND SLEEP(5)--                        |

  @security @sql-injection
  Scenario Outline: SQL injection payloads in the password field are rejected
    Given the user is on the login page
    When the user enters email "testuser@example.com" and password "<sql_payload>"
    And the user clicks the "Login" button
    Then the login should fail with "Invalid email or password."
    And no SQL error or stack trace should be visible in the response

    Examples:
      | sql_payload             |
      | ' OR '1'='1             |
      | ' OR 1=1--              |
      | password' OR 'x'='x     |
      | '; DROP TABLE users; -- |

# =============================================================================
# SECTION 5 — Script Injection (XSS) Attempts
# =============================================================================

  @security @xss
  Scenario Outline: Script injection payloads in the email field are sanitised
    Given the user is on the login page
    When the user enters email "<xss_payload>" and password "Test@12345"
    And the user clicks the "Login" button
    Then the payload should not be executed in the browser
    And the response should not reflect the raw script

    Examples:
      | xss_payload                                          |
      | <script>alert('XSS')</script>@example.com            |
      | "><img src=x onerror=alert(1)>@example.com           |
      | javascript:alert(1)@example.com                      |
      | <svg onload=alert(document.cookie)>@example.com      |

  @security @xss
  Scenario: Script injection payload in the password field is not reflected in the response
    Given the user is on the login page
    When the user enters email "testuser@example.com" and password "<script>alert('XSS')</script>"
    And the user clicks the "Login" button
    Then the login should fail
    And the script should not be executed or echoed back in any response body

# =============================================================================
# SECTION 6 — Brute-Force Lockout Validation
# =============================================================================

  @security @lockout
  Scenario: Account is locked after 5 consecutive failed login attempts
    Given the user is on the login page
    And the user "testuser@example.com" has 0 failed attempts
    When the user enters incorrect credentials 5 times consecutively for "testuser@example.com"
    Then the account "testuser@example.com" should be locked
    And the error message "Your account has been temporarily locked due to multiple failed login attempts. Please try again after 15 minutes." should be displayed
    And no further login attempt should be accepted for the next 15 minutes

  @security @lockout
  Scenario: Locked account cannot login with correct credentials during the lockout period
    Given the account "testuser@example.com" is locked due to failed attempts
    And the lockout period has not expired
    When the user enters email "testuser@example.com" and password "Test@12345"
    And the user clicks the "Login" button
    Then the login should fail
    And the error message "Your account is temporarily locked. Please try again after 15 minutes." should be displayed

  @security @lockout
  Scenario: Account is automatically unlocked after 15 minutes of lockout
    Given the account "testuser@example.com" was locked 15 minutes and 1 second ago
    When the user enters email "testuser@example.com" and password "Test@12345"
    And the user clicks the "Login" button
    Then the user should be redirected to the dashboard
    And the failed attempt counter should be reset to 0

  @security @lockout
  Scenario: Failed attempt counter resets after successful login before reaching the threshold
    Given the user is on the login page
    And the user "testuser@example.com" has 4 failed attempts recorded
    When the user enters email "testuser@example.com" and password "Test@12345"
    And the user clicks the "Login" button
    Then the user should be redirected to the dashboard
    And the failed attempt counter for "testuser@example.com" should be reset to 0

  @security @lockout
  Scenario: Lockout is per account and does not affect other accounts
    Given the account "testuser@example.com" is locked
    When the user enters email "anotheruser@example.com" and password "ValidPass@1"
    And the user clicks the "Login" button
    Then "anotheruser@example.com" should be logged in successfully

  @security @lockout
  Scenario: Remaining lockout time is shown accurately after an attempt during lockout
    Given the account "testuser@example.com" was locked 5 minutes ago
    When the user attempts to login with correct credentials for "testuser@example.com"
    Then the error should indicate approximately 10 minutes remaining

# =============================================================================
# SECTION 7 — Session Expiry Validation
# =============================================================================

  @session
  Scenario: Authenticated session expires after 30 minutes of inactivity
    Given the user "testuser@example.com" is successfully logged in
    And the user has been inactive for 30 minutes and 1 second
    When the user attempts to access a protected resource "/dashboard"
    Then the user should be redirected to the login page
    And the message "Your session has expired. Please log in again." should be displayed

  @session
  Scenario: Session remains active when user is continuously active within 30 minutes
    Given the user "testuser@example.com" is successfully logged in
    And the user performs an action every 10 minutes
    When 30 minutes have elapsed since login
    Then the user should still be authenticated
    And access to "/dashboard" should be granted

  @session
  Scenario: Session inactivity timer resets on each user action
    Given the user "testuser@example.com" is logged in
    And the user has been inactive for 29 minutes
    When the user makes a valid API call
    Then the inactivity timer should reset to 30 minutes

  @session
  Scenario: Expired JWT token is rejected by the backend
    Given a JWT token that was issued 31 minutes ago without activity
    When a request is made to a protected endpoint with the expired token
    Then the API should return HTTP 401 Unauthorized
    And the response body should contain "Token has expired."

  @session
  Scenario: Accessing the login page while already authenticated redirects to dashboard
    Given the user "testuser@example.com" is logged in with a valid active session
    When the user navigates to the login page URL directly
    Then the user should be redirected to the dashboard

# =============================================================================
# SECTION 8 — Token Invalidation After Logout
# =============================================================================

  @logout @security
  Scenario: JWT token is invalidated upon logout
    Given the user "testuser@example.com" is logged in with a valid JWT token
    When the user clicks the "Logout" button
    Then the user should be redirected to the login page
    And the JWT token should be added to the server-side token blacklist
    And the token should be cleared from session storage

  @logout @security
  Scenario: Using an invalidated token after logout returns 401 Unauthorized
    Given the user "testuser@example.com" was logged in and has since logged out
    And the JWT token was captured before logout
    When a request is made to a protected endpoint using the captured token
    Then the API should return HTTP 401 Unauthorized
    And the response body should contain "Token is invalid or has been revoked."

  @logout @security
  Scenario: Browser back button after logout does not restore authenticated session
    Given the user "testuser@example.com" logs out from the dashboard
    When the user presses the browser back button
    Then the user should remain on the login page or be redirected to it
    And the cached page should not display authenticated content

  @logout
  Scenario: Logging out from one device does not invalidate sessions on other devices
    Given the user "testuser@example.com" is logged in on Device A and Device B
    When the user logs out from Device A
    Then the session on Device B should remain valid
    And the user on Device B should still be able to access protected resources

# =============================================================================
# SECTION 9 — Error Message Validation
# =============================================================================

  @error-messages
  Scenario: Error message does not expose internal system details
    Given the user is on the login page
    When the user submits an invalid login attempt
    Then the error message should not contain any of the following:
      | Stack trace information         |
      | Database connection strings     |
      | Internal server file paths      |
      | SQL query details               |
      | Framework version information   |

  @error-messages
  Scenario: Error messages are displayed in a user-friendly and accessible manner
    Given the user is on the login page
    When the user submits the login form with empty credentials
    Then validation error messages should be visible on screen
    And error messages should have sufficient color contrast (WCAG AA)
    And error messages should be associated with their respective fields via ARIA attributes

  @error-messages
  Scenario: HTTP 429 Too Many Requests is returned when brute-forcing via API
    Given an attacker sends 10 login requests per second to the authentication API
    When the rate limit is exceeded
    Then the API should return HTTP 429 Too Many Requests
    And a "Retry-After" header should be present in the response

  @error-messages
  Scenario: Login form submission via HTTP (non-HTTPS) is rejected or redirected
    Given the application enforces HTTPS
    When the user submits login credentials over plain HTTP
    Then the request should be redirected to HTTPS
    And credentials should not be transmitted in plain text

# =============================================================================
# SECTION 10 — Password Reset Flow Validation
# =============================================================================

  @password-reset
  Scenario: Password reset email is sent for a registered email address
    Given the user is on the "Forgot Password" page
    When the user enters the registered email "testuser@example.com"
    And the user clicks "Send Reset Link"
    Then a password reset email should be sent to "testuser@example.com"
    And the success message "If an account exists for this email, a reset link has been sent." should be displayed

  @password-reset
  Scenario: Password reset request for an unregistered email gives generic response (no user enumeration)
    Given the user is on the "Forgot Password" page
    When the user enters the unregistered email "unknown@example.com"
    And the user clicks "Send Reset Link"
    Then the same success message "If an account exists for this email, a reset link has been sent." should be displayed
    And no reset email should be sent

  @password-reset
  Scenario: Password reset link is functional and leads to the reset password form
    Given a valid password reset link has been sent to "testuser@example.com"
    When the user clicks the reset link within 1 hour
    Then the user should be directed to the password reset form
    And the token in the URL should be validated successfully

  @password-reset
  Scenario: Password reset link expires after 1 hour
    Given a password reset link was generated 1 hour and 1 second ago for "testuser@example.com"
    When the user clicks the expired reset link
    Then the user should see the error "This password reset link has expired. Please request a new one."
    And the user should not be able to reset their password using the expired link

  @password-reset
  Scenario: Password reset token can only be used once
    Given a valid password reset link for "testuser@example.com"
    When the user uses the reset link to successfully change their password
    And the user tries to use the same reset link again
    Then the user should see the error "This password reset link is invalid or has already been used."

  @password-reset
  Scenario: New password must meet complexity requirements during reset
    Given the user is on the password reset form with a valid token
    When the user enters a new password "simple" that does not meet complexity requirements
    And the user clicks "Reset Password"
    Then the validation error "Password must be at least 8 characters and include uppercase, lowercase, number, and special character." should be displayed

  @password-reset
  Scenario: Successful password reset allows login with the new password
    Given the user has successfully reset their password to "NewPass@9876"
    When the user navigates to the login page
    And the user enters email "testuser@example.com" and password "NewPass@9876"
    And the user clicks the "Login" button
    Then the user should be redirected to the dashboard

  @password-reset
  Scenario: Old password cannot be used to login after a successful password reset
    Given the user has successfully reset their password from "Test@12345" to "NewPass@9876"
    When the user tries to login with email "testuser@example.com" and the old password "Test@12345"
    Then the login should fail with "Invalid email or password."

  @password-reset
  Scenario: All active sessions are invalidated after a password reset
    Given the user "testuser@example.com" has active sessions on multiple devices
    When the user resets their password successfully
    Then all existing JWT tokens for "testuser@example.com" should be invalidated
    And all active sessions should be terminated
    And re-authentication should be required on all devices
