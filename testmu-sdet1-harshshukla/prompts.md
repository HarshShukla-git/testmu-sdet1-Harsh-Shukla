# Login Module – Prompt

You are a QA engineer designing regression coverage for a web application.

Generate test cases in Gherkin syntax for a Login module.

The module supports:
- Email and password authentication
- Account lock after multiple failed login attempts
- Password reset functionality
- Session timeout after inactivity

Cover the following:
- Valid login
- Invalid credentials
- Forgot password
- Session expiry
- Brute-force lockout

Provide clear Given-When-Then steps.

Output only Gherkin scenarios.

# Login Module – Reflection

The refined prompt significantly improved coverage depth by explicitly specifying:
- Lockout duration
- Session timeout behavior
- Token invalidation
- Security attack vectors (SQL/XSS)
- Password reset lifecycle

The output demonstrated structured tagging, boundary analysis, API-level validation, and accessibility considerations, reducing the need for manual augmentation.


# Dashboard Module – Prompt 

You are a senior SDET designing production-grade regression coverage for a web-based dashboard application.

Generate comprehensive regression test cases in valid Gherkin syntax for the Dashboard module.

Application Context:
- Dashboard contains widgets: Sales Summary, Active Users, Notifications
- Data is fetched via backend REST APIs
- Supports filtering and sorting
- Role-based visibility (Admin vs Standard User)
- Responsive design (Desktop, Tablet, Mobile)
- Widgets load independently (micro-frontend style)
- Some widgets depend on real-time data updates

Coverage Requirements:
- Widget load validation
- API data consistency validation
- Partial widget failure handling
- Empty state handling
- Filter and sort correctness
- Role-based visibility validation
- Unauthorized access prevention
- Slow API response handling
- Responsive layout validation
- Real-time data refresh behavior
- Caching behavior validation
- Error message validation
- Accessibility checks (ARIA roles, contrast)
- Performance thresholds (page load under 3 seconds)

For each scenario:
- Use clear Given-When-Then steps
- Include example input or mock API response
- Specify expected UI and backend behavior

Output only valid Gherkin scenarios.

# REST API Module – Prompt

You are a senior SDET focusing on API regression coverage for a production-grade REST system.

Generate comprehensive API regression test cases in Gherkin or structured JSON format for REST endpoints managing Users and Items.

Application Context:
- JWT authentication required for protected endpoints
- CRUD operations available on /items
- Rate limit: 100 requests per minute per user
- Standard HTTP status codes used (200, 201, 400, 401, 403, 404, 409, 429, 500)
- JSON schema validation required for all successful responses
- Optimistic locking used for concurrent updates (version field)

Coverage Requirements:
- Valid and expired JWT token validation
- Missing or malformed Authorization header
- Positive CRUD scenarios
- Invalid payload validation
- Required field validation
- Boundary value testing
- Concurrent update conflict handling (409 Conflict)
- Rate limiting enforcement (429 Too Many Requests)
- Unauthorized access attempts
- Internal server error handling (500)
- Response schema validation
- Idempotency validation for PUT and DELETE
- Data consistency after create/update/delete operations

For each test case:
- Include sample request
- Include expected status code
- Include expected response body structure
- Clearly define validation points

Output structured scenarios only.