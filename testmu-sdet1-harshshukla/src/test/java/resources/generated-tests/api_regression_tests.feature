# ============================================================
# Feature: REST API Module – Regression Test Suite
# System: Production-Grade REST API (Users & Items)
# Author: Senior SDET
# Coverage: JWT Auth, CRUD, Validation, Rate Limiting,
#           Concurrency, Schema, Idempotency, Data Consistency
# ============================================================

Feature: REST API Regression – Users and Items Endpoints

  Background:
    Given the API base URL is "https://api.example.com"
    And the Content-Type header is "application/json"

  # ============================================================
  # 1. JWT TOKEN VALIDATION
  # ============================================================

  @auth @jwt
  Scenario: Valid JWT token grants access to a protected endpoint
    Given I have a valid JWT token for user "testuser@example.com"
    When I send a GET request to "/items" with the Authorization header "Bearer <valid_token>"
    Then the response status code should be 200
    And the response body should be a valid JSON array
    And the response header "Content-Type" should contain "application/json"

  @auth @jwt
  Scenario: Expired JWT token returns 401 Unauthorized
    Given I have an expired JWT token
    When I send a GET request to "/items" with the Authorization header "Bearer <expired_token>"
    Then the response status code should be 401
    And the response body should match:
      """
      {
        "error": "unauthorized",
        "message": "Token has expired"
      }
      """

  @auth @jwt
  Scenario: JWT token with invalid signature returns 401 Unauthorized
    Given I construct a JWT token with a tampered signature
    When I send a GET request to "/items" with the Authorization header "Bearer <tampered_token>"
    Then the response status code should be 401
    And the response body field "message" should equal "Invalid token signature"

  @auth @jwt
  Scenario: JWT token issued for a different audience is rejected
    Given I have a JWT token scoped for audience "other-service"
    When I send a GET request to "/items" with that token
    Then the response status code should be 401
    And the response body field "message" should equal "Token audience mismatch"

  # ============================================================
  # 2. MISSING OR MALFORMED AUTHORIZATION HEADER
  # ============================================================

  @auth @header-validation
  Scenario: Request with no Authorization header returns 401
    Given I do not include an Authorization header
    When I send a GET request to "/items"
    Then the response status code should be 401
    And the response body should match:
      """
      {
        "error": "unauthorized",
        "message": "Authorization header is missing"
      }
      """

  @auth @header-validation
  Scenario: Authorization header with wrong scheme returns 401
    Given I set the Authorization header to "Basic dXNlcjpwYXNz"
    When I send a GET request to "/items"
    Then the response status code should be 401
    And the response body field "message" should equal "Unsupported authentication scheme. Expected Bearer"

  @auth @header-validation
  Scenario: Authorization header with Bearer but no token value returns 401
    Given I set the Authorization header to "Bearer "
    When I send a GET request to "/items"
    Then the response status code should be 401
    And the response body field "message" should equal "Token is missing or empty"

  @auth @header-validation
  Scenario: Authorization header with malformed JWT (not 3 segments) returns 401
    Given I set the Authorization header to "Bearer abc.def"
    When I send a GET request to "/items"
    Then the response status code should be 401
    And the response body field "message" should equal "Malformed JWT token"

  # ============================================================
  # 3. POSITIVE CRUD SCENARIOS – ITEMS
  # ============================================================

  @crud @create
  Scenario: Successfully create a new item returns 201 Created
    Given I have a valid JWT token
    And the request body is:
      """
      {
        "name": "Laptop Stand",
        "description": "Adjustable aluminium laptop stand",
        "price": 49.99,
        "quantity": 100
      }
      """
    When I send a POST request to "/items"
    Then the response status code should be 201
    And the response body should contain:
      | Field       | Value                             |
      | name        | Laptop Stand                      |
      | description | Adjustable aluminium laptop stand |
      | price       | 49.99                             |
      | quantity    | 100                               |
    And the response body should contain a non-null "id" field
    And the response body should contain a non-null "createdAt" field
    And the response body should contain a "version" field equal to 1

  @crud @read
  Scenario: Successfully retrieve all items returns 200 OK
    Given I have a valid JWT token
    And at least one item exists in the system
    When I send a GET request to "/items"
    Then the response status code should be 200
    And the response body should be a JSON array
    And each item in the array should contain fields: "id", "name", "price", "quantity", "version"

  @crud @read
  Scenario: Successfully retrieve a single item by ID returns 200 OK
    Given I have a valid JWT token
    And an item exists with id "item-001"
    When I send a GET request to "/items/item-001"
    Then the response status code should be 200
    And the response body should contain:
      | Field | Value    |
      | id    | item-001 |
    And the response body should include fields: "name", "description", "price", "quantity", "createdAt", "version"

  @crud @update
  Scenario: Successfully update an existing item returns 200 OK
    Given I have a valid JWT token
    And an item exists with id "item-001" and current version 1
    And the request body is:
      """
      {
        "name": "Laptop Stand Pro",
        "price": 59.99,
        "quantity": 80,
        "version": 1
      }
      """
    When I send a PUT request to "/items/item-001"
    Then the response status code should be 200
    And the response body field "name" should equal "Laptop Stand Pro"
    And the response body field "price" should equal 59.99
    And the response body field "version" should equal 2

  @crud @delete
  Scenario: Successfully delete an existing item returns 204 No Content
    Given I have a valid JWT token
    And an item exists with id "item-002"
    When I send a DELETE request to "/items/item-002"
    Then the response status code should be 204
    And the response body should be empty

  @crud @delete
  Scenario: Deleted item is no longer retrievable
    Given I have a valid JWT token
    And I have successfully deleted item with id "item-002"
    When I send a GET request to "/items/item-002"
    Then the response status code should be 404
    And the response body field "message" should equal "Item not found"

  # ============================================================
  # 4. INVALID PAYLOAD VALIDATION
  # ============================================================

  @validation @payload
  Scenario: Creating an item with non-numeric price returns 400 Bad Request
    Given I have a valid JWT token
    And the request body is:
      """
      {
        "name": "Keyboard",
        "price": "free",
        "quantity": 50
      }
      """
    When I send a POST request to "/items"
    Then the response status code should be 400
    And the response body should match:
      """
      {
        "error": "validation_error",
        "field": "price",
        "message": "price must be a valid number"
      }
      """

  @validation @payload
  Scenario: Creating an item with invalid JSON body returns 400 Bad Request
    Given I have a valid JWT token
    And the request body is the malformed string: "{ name: Laptop, price: }"
    When I send a POST request to "/items"
    Then the response status code should be 400
    And the response body field "error" should equal "invalid_json"

  @validation @payload
  Scenario: Updating an item with an empty request body returns 400 Bad Request
    Given I have a valid JWT token
    And an item exists with id "item-001"
    When I send a PUT request to "/items/item-001" with an empty JSON body "{}"
    Then the response status code should be 400
    And the response body field "message" should contain "Request body must not be empty"

  @validation @payload
  Scenario: Creating an item with extra unknown fields ignores them and returns 201
    Given I have a valid JWT token
    And the request body is:
      """
      {
        "name": "Monitor Arm",
        "price": 79.99,
        "quantity": 30,
        "unknownField": "should be ignored"
      }
      """
    When I send a POST request to "/items"
    Then the response status code should be 201
    And the response body should NOT contain a field "unknownField"

  # ============================================================
  # 5. REQUIRED FIELD VALIDATION
  # ============================================================

  @validation @required-fields
  Scenario: Creating an item without required "name" field returns 400
    Given I have a valid JWT token
    And the request body is:
      """
      {
        "price": 29.99,
        "quantity": 10
      }
      """
    When I send a POST request to "/items"
    Then the response status code should be 400
    And the response body should contain:
      | Field   | Value                    |
      | error   | validation_error         |
      | field   | name                     |
      | message | name is required         |

  @validation @required-fields
  Scenario: Creating an item without required "price" field returns 400
    Given I have a valid JWT token
    And the request body is:
      """
      {
        "name": "USB Hub",
        "quantity": 25
      }
      """
    When I send a POST request to "/items"
    Then the response status code should be 400
    And the response body field "field" should equal "price"
    And the response body field "message" should equal "price is required"

  @validation @required-fields
  Scenario: Creating an item with null required field returns 400
    Given I have a valid JWT token
    And the request body is:
      """
      {
        "name": null,
        "price": 19.99,
        "quantity": 5
      }
      """
    When I send a POST request to "/items"
    Then the response status code should be 400
    And the response body field "message" should equal "name must not be null"

  @validation @required-fields
  Scenario: Updating an item without providing version field returns 400
    Given I have a valid JWT token
    And an item exists with id "item-001"
    And the request body does not include the "version" field
    When I send a PUT request to "/items/item-001"
    Then the response status code should be 400
    And the response body field "message" should equal "version is required for updates"

  # ============================================================
  # 6. BOUNDARY VALUE TESTING
  # ============================================================

  @boundary
  Scenario: Creating an item with name at maximum length (255 chars) succeeds
    Given I have a valid JWT token
    And the request body contains "name" as a 255-character string
    When I send a POST request to "/items"
    Then the response status code should be 201

  @boundary
  Scenario: Creating an item with name exceeding maximum length (256 chars) returns 400
    Given I have a valid JWT token
    And the request body contains "name" as a 256-character string
    When I send a POST request to "/items"
    Then the response status code should be 400
    And the response body field "message" should equal "name must not exceed 255 characters"

  @boundary
  Scenario: Creating an item with price of 0.01 (minimum valid price) succeeds
    Given I have a valid JWT token
    And the request body contains "price" as 0.01
    When I send a POST request to "/items"
    Then the response status code should be 201
    And the response body field "price" should equal 0.01

  @boundary
  Scenario: Creating an item with negative price returns 400
    Given I have a valid JWT token
    And the request body contains "price" as -1.00
    When I send a POST request to "/items"
    Then the response status code should be 400
    And the response body field "message" should equal "price must be greater than 0"

  @boundary
  Scenario: Creating an item with quantity of 0 returns 400
    Given I have a valid JWT token
    And the request body contains "quantity" as 0
    When I send a POST request to "/items"
    Then the response status code should be 400
    And the response body field "message" should equal "quantity must be at least 1"

  @boundary
  Scenario: Creating an item with quantity at maximum allowed value (10000) succeeds
    Given I have a valid JWT token
    And the request body contains "quantity" as 10000
    When I send a POST request to "/items"
    Then the response status code should be 201

  @boundary
  Scenario: Creating an item with quantity exceeding maximum (10001) returns 400
    Given I have a valid JWT token
    And the request body contains "quantity" as 10001
    When I send a POST request to "/items"
    Then the response status code should be 400
    And the response body field "message" should equal "quantity must not exceed 10000"

  @boundary
  Scenario: Creating an item with empty string name returns 400
    Given I have a valid JWT token
    And the request body contains "name" as ""
    When I send a POST request to "/items"
    Then the response status code should be 400
    And the response body field "message" should equal "name must not be blank"

  # ============================================================
  # 7. CONCURRENT UPDATE CONFLICT – OPTIMISTIC LOCKING (409)
  # ============================================================

  @concurrency @conflict
  Scenario: Concurrent update with stale version returns 409 Conflict
    Given I have a valid JWT token
    And an item exists with id "item-001" and current version 3
    And the request body is:
      """
      {
        "name": "Updated Name",
        "price": 55.00,
        "quantity": 20,
        "version": 2
      }
      """
    When I send a PUT request to "/items/item-001"
    Then the response status code should be 409
    And the response body should match:
      """
      {
        "error": "conflict",
        "message": "Update conflict: item has been modified by another request. Current version is 3."
      }
      """

  @concurrency @conflict
  Scenario: Concurrent update with correct current version succeeds
    Given I have a valid JWT token
    And an item exists with id "item-001" and current version 3
    And the request body includes "version": 3
    When I send a PUT request to "/items/item-001"
    Then the response status code should be 200
    And the response body field "version" should equal 4

  @concurrency @conflict
  Scenario: Two simultaneous PUT requests only one succeeds
    Given I have a valid JWT token
    And item "item-003" exists with version 1
    When I send two simultaneous PUT requests to "/items/item-003" both with version 1
    Then exactly one request should return status 200
    And exactly one request should return status 409
    And the final item version should be 2

  # ============================================================
  # 8. RATE LIMITING (429 TOO MANY REQUESTS)
  # ============================================================

  @rate-limit
  Scenario: Requests within rate limit are served successfully
    Given I have a valid JWT token for user "ratetest@example.com"
    When I send 99 GET requests to "/items" within 1 minute
    Then all 99 responses should have status code 200
    And the response header "X-RateLimit-Remaining" should decrease with each request

  @rate-limit
  Scenario: 101st request within one minute returns 429 Too Many Requests
    Given I have a valid JWT token for user "ratetest@example.com"
    And I have already sent 100 requests within the current minute
    When I send one more GET request to "/items"
    Then the response status code should be 429
    And the response body should match:
      """
      {
        "error": "rate_limit_exceeded",
        "message": "Too many requests. Limit: 100 per minute.",
        "retryAfter": "<seconds_until_window_resets>"
      }
      """
    And the response header "Retry-After" should be present and contain a positive integer
    And the response header "X-RateLimit-Limit" should equal "100"
    And the response header "X-RateLimit-Remaining" should equal "0"

  @rate-limit
  Scenario: Rate limit resets after the time window expires
    Given I have a valid JWT token for user "ratetest@example.com"
    And I have hit the rate limit (100 requests in the current window)
    When 60 seconds elapse and I send a new GET request to "/items"
    Then the response status code should be 200
    And the response header "X-RateLimit-Remaining" should equal "99"

  @rate-limit
  Scenario: Rate limits are scoped per user and not global
    Given user "userA@example.com" has hit the rate limit
    When user "userB@example.com" sends a GET request to "/items" with their valid token
    Then the response status code should be 200
    And user B should not be affected by user A's rate limit

  # ============================================================
  # 9. UNAUTHORIZED ACCESS ATTEMPTS
  # ============================================================

  @auth @unauthorized
  Scenario: Accessing a protected endpoint without authentication returns 401
    Given I do not include any Authorization header
    When I send a POST request to "/items" with a valid body
    Then the response status code should be 401
    And the response body field "error" should equal "unauthorized"

  @auth @unauthorized
  Scenario: Standard user cannot delete another user's item
    Given I am authenticated as "standard-user" with a valid token
    And item "item-999" is owned by "other-user"
    When I send a DELETE request to "/items/item-999"
    Then the response status code should be 403
    And the response body should match:
      """
      {
        "error": "forbidden",
        "message": "You do not have permission to delete this item"
      }
      """

  @auth @unauthorized
  Scenario: Standard user cannot access admin-scoped user management endpoint
    Given I am authenticated as "standard-user"
    When I send a GET request to "/admin/users"
    Then the response status code should be 403
    And the response body field "message" should equal "Access denied: admin role required"

  @auth @unauthorized
  Scenario: Accessing a non-existent endpoint returns 404 not 401
    Given I have a valid JWT token
    When I send a GET request to "/nonexistent-endpoint"
    Then the response status code should be 404

  # ============================================================
  # 10. INTERNAL SERVER ERROR HANDLING (500)
  # ============================================================

  @error-handling
  Scenario: API returns 500 and does not expose stack trace to the client
    Given I have a valid JWT token
    And the database is configured to throw an internal error on next request
    When I send a GET request to "/items"
    Then the response status code should be 500
    And the response body should match:
      """
      {
        "error": "internal_server_error",
        "message": "An unexpected error occurred. Please try again later."
      }
      """
    And the response body should NOT contain fields: "stackTrace", "exception", "cause"

  @error-handling
  Scenario: API returns 500 with a traceable correlation ID
    Given I have a valid JWT token
    And the system is configured to return a 500 error
    When I send a GET request to "/items"
    Then the response status code should be 500
    And the response body should contain a non-null "correlationId" field
    And the response header "X-Correlation-ID" should match the body "correlationId"

  # ============================================================
  # 11. RESPONSE SCHEMA VALIDATION
  # ============================================================

  @schema
  Scenario: GET /items response matches the defined JSON schema
    Given I have a valid JWT token
    When I send a GET request to "/items"
    Then the response status code should be 200
    And the response body should conform to the following schema:
      """
      {
        "type": "array",
        "items": {
          "type": "object",
          "required": ["id", "name", "price", "quantity", "version", "createdAt"],
          "properties": {
            "id":          { "type": "string" },
            "name":        { "type": "string" },
            "description": { "type": "string" },
            "price":       { "type": "number", "minimum": 0.01 },
            "quantity":    { "type": "integer", "minimum": 1 },
            "version":     { "type": "integer", "minimum": 1 },
            "createdAt":   { "type": "string", "format": "date-time" },
            "updatedAt":   { "type": "string", "format": "date-time" }
          }
        }
      }
      """

  @schema
  Scenario: POST /items success response matches the defined JSON schema
    Given I have a valid JWT token
    And I send a valid POST request to "/items"
    Then the response body should conform to the following schema:
      """
      {
        "type": "object",
        "required": ["id", "name", "price", "quantity", "version", "createdAt"],
        "properties": {
          "id":        { "type": "string", "format": "uuid" },
          "name":      { "type": "string", "minLength": 1 },
          "price":     { "type": "number" },
          "quantity":  { "type": "integer" },
          "version":   { "type": "integer", "enum": [1] },
          "createdAt": { "type": "string", "format": "date-time" }
        }
      }
      """

  @schema
  Scenario: Error response always conforms to the standard error schema
    Given I have a valid JWT token
    When any API endpoint returns an error (4xx or 5xx)
    Then the response body should always conform to:
      """
      {
        "type": "object",
        "required": ["error", "message"],
        "properties": {
          "error":   { "type": "string" },
          "message": { "type": "string" },
          "field":   { "type": "string" },
          "correlationId": { "type": "string" }
        }
      }
      """

  # ============================================================
  # 12. IDEMPOTENCY VALIDATION – PUT AND DELETE
  # ============================================================

  @idempotency
  Scenario: Sending the same PUT request twice with same version produces consistent result
    Given I have a valid JWT token
    And item "item-001" exists with version 1
    And the request body is:
      """
      {
        "name": "Wireless Mouse",
        "price": 35.00,
        "quantity": 60,
        "version": 1
      }
      """
    When I send the PUT request to "/items/item-001" the first time
    Then the response status code should be 200
    And the response body field "version" should equal 2
    When I send the same PUT request to "/items/item-001" again with version 1
    Then the response status code should be 409
    And the item version in the system should remain 2

  @idempotency
  Scenario: Sending DELETE to the same item twice returns 204 then 404
    Given I have a valid JWT token
    And item "item-005" exists
    When I send a DELETE request to "/items/item-005" the first time
    Then the response status code should be 204
    When I send a DELETE request to "/items/item-005" again
    Then the response status code should be 404
    And the response body field "message" should equal "Item not found"

  @idempotency
  Scenario: PUT with an identical payload and correct version increments version each time
    Given I have a valid JWT token
    And item "item-006" exists with version 1
    When I send PUT to "/items/item-006" with version 1 using payload A
    Then the response status code should be 200 and version becomes 2
    When I send PUT to "/items/item-006" with version 2 using the same payload A
    Then the response status code should be 200 and version becomes 3
    And the final item data in the system reflects payload A

  # ============================================================
  # 13. DATA CONSISTENCY AFTER CREATE / UPDATE / DELETE
  # ============================================================

  @data-consistency
  Scenario: Item created via POST is immediately retrievable via GET
    Given I have a valid JWT token
    When I send a POST request to "/items" with body:
      """
      {
        "name": "Ergonomic Chair",
        "price": 299.99,
        "quantity": 15
      }
      """
    Then the response status code should be 201
    And the response body contains "id" as "new-item-id"
    When I send a GET request to "/items/new-item-id"
    Then the response status code should be 200
    And the response body field "name" should equal "Ergonomic Chair"
    And the response body field "price" should equal 299.99

  @data-consistency
  Scenario: Updated item reflects changes immediately on subsequent GET
    Given I have a valid JWT token
    And item "item-007" exists with name "Standing Desk" and price 350.00
    When I send a PUT request to "/items/item-007" with updated price 399.00 and version 1
    Then the response status code should be 200
    When I send a GET request to "/items/item-007"
    Then the response status code should be 200
    And the response body field "price" should equal 399.00
    And the response body field "name" should equal "Standing Desk"

  @data-consistency
  Scenario: Deleted item does not appear in the GET all items list
    Given I have a valid JWT token
    And item "item-008" exists
    When I send a DELETE request to "/items/item-008"
    Then the response status code should be 204
    When I send a GET request to "/items"
    Then the response status code should be 200
    And item "item-008" should NOT appear in the response array

  @data-consistency
  Scenario: Creating multiple items does not affect existing items
    Given I have a valid JWT token
    And item "item-010" exists with name "Webcam" and price 89.99
    When I create 3 additional items via POST requests
    Then the GET response for "/items/item-010" should still return name "Webcam" and price 89.99
    And the total item count in GET /items should increase by 3

  @data-consistency
  Scenario: Failed update due to 409 conflict does not alter item state
    Given I have a valid JWT token
    And item "item-011" exists with version 5 and name "Original Name"
    When I send a PUT request to "/items/item-011" with version 4 and name "Changed Name"
    Then the response status code should be 409
    When I send a GET request to "/items/item-011"
    Then the response body field "name" should equal "Original Name"
    And the response body field "version" should equal 5

  # ============================================================
  # 14. ADDITIONAL EDGE CASES
  # ============================================================

  @edge-cases
  Scenario: GET /items/{id} for a non-existent item returns 404
    Given I have a valid JWT token
    When I send a GET request to "/items/nonexistent-id-99999"
    Then the response status code should be 404
    And the response body field "error" should equal "not_found"
    And the response body field "message" should equal "Item not found"

  @edge-cases
  Scenario: Pagination parameters return correct subset of items
    Given I have a valid JWT token
    And 50 items exist in the system
    When I send a GET request to "/items?page=1&pageSize=10"
    Then the response status code should be 200
    And the response body should contain exactly 10 items
    And the response metadata should include "totalCount", "page", "pageSize", "totalPages"

  @edge-cases
  Scenario: Search filter returns only matching items
    Given I have a valid JWT token
    And items exist with names "Keyboard", "Keyboard Pro", "Mouse"
    When I send a GET request to "/items?search=Keyboard"
    Then the response status code should be 200
    And the response array should contain items with names "Keyboard" and "Keyboard Pro"
    And the response array should NOT contain an item with name "Mouse"

  @edge-cases
  Scenario: PATCH method on /items returns 405 Method Not Allowed
    Given I have a valid JWT token
    When I send a PATCH request to "/items/item-001"
    Then the response status code should be 405
    And the response header "Allow" should contain "GET, POST, PUT, DELETE"

  @edge-cases
  Scenario: SQL injection attempt in item name is safely stored as plain text
    Given I have a valid JWT token
    And the request body is:
      """
      {
        "name": "'; DROP TABLE items; --",
        "price": 10.00,
        "quantity": 1
      }
      """
    When I send a POST request to "/items"
    Then the response status code should be 201
    And the response body field "name" should equal "'; DROP TABLE items; --" as plain text
    And the database should not execute any destructive operation
