# TestMu AI Talent Assessment

## SDET-1 \| AI-Native Quality Engineering Challenge

------------------------------------------------------------------------

## Overview

This project demonstrates AI-native test automation using Selenium,
TestNG, and real OpenAI API integration.

The goal was not just to automate tests, but to integrate AI directly
into the regression workflow to reduce manual debugging effort across
Login, Dashboard, and API modules.

This solution includes:

-   Structured regression test generation using LLM prompts
-   Documented prompt engineering process
-   Real-time AI-powered failure analysis
-   Clean modular automation architecture
-   Non-mocked LLM integration inside the test lifecycle

------------------------------------------------------------------------

## Tech Stack

-   Java 17\
-   Selenium WebDriver\
-   TestNG\
-   Maven\
-   OkHttp (HTTP client)\
-   OpenAI API (GPT-4o-mini)

------------------------------------------------------------------------

## Project Structure

src/ ├── main/java │ ├── base/ → WebDriver setup & teardown │ ├──
listeners/ → TestNG failure listener │ ├── llm/ → LLM client & failure
explainer │ └── utils/ │ └── test/java ├── login/ ├── dashboard/ └──
api/

src/test/resources/generated-tests/ ├── login_v1.feature ├──
dashboard_regression_tests.feature └── api_regression_tests.feature

Root: ├── prompts.md ├── ai-usage-log.md ├── README.md ├── pom.xml

------------------------------------------------------------------------

# Task 2 --- Prompt Engineering for Test Generation

LLMs were used to generate structured regression coverage for:

-   Login module
-   Dashboard module
-   REST API module

All raw prompts (without cleanup) are documented in: prompts.md

The generated outputs include:

-   Positive scenarios
-   Negative scenarios
-   Boundary validations
-   Security testing (SQL Injection, XSS)
-   Session expiry handling
-   Rate limiting validation
-   Token validation
-   Permission-based visibility checks
-   Error handling (4xx/5xx)

Prompt refinement iterations demonstrate reasoning evolution and
improved output quality.

------------------------------------------------------------------------

# Task 3 --- LLM Integration in Test Framework

## Chosen Option: Option A --- Failure Explainer

### Why Option A?

-   Provides immediate debugging assistance
-   Reduces Mean Time To Resolution (MTTR)
-   Integrates AI directly into the test lifecycle
-   Enables contextual root cause analysis per failure
-   More actionable than post-run log classification

------------------------------------------------------------------------

## How It Works

When a test fails:

1.  TestNG Listener (TestFailureListener) is triggered.
2.  The framework captures:
    -   Test name
    -   Assertion error message
    -   Current URL
    -   Page HTML snapshot
3.  This context is sent to OpenAI using LLMClient.
4.  The LLM returns:
    -   Root cause analysis
    -   Failure classification
    -   Suggested fix
    -   Confidence level
5.  The result is written automatically to:

/reports/ai-failure-report.txt

This is a real API call --- not mocked.

------------------------------------------------------------------------

## How To Run

### 1. Set OpenAI API Key

On Windows:

setx OPENAI_API_KEY "your_api_key_here"

Restart Eclipse after setting it.

------------------------------------------------------------------------

### 2. Run Tests

Run LoginTest via TestNG.

To trigger AI explanation:

-   Temporarily force an assertion failure.
-   Check /reports/ai-failure-report.txt for AI-generated analysis.

------------------------------------------------------------------------

## Future Improvements

-   Structured JSON response parsing
-   Allure / Extent report integration
-   Slack / Teams notifications
-   Flaky test auto-detection
-   AI-based retry decision engine

------------------------------------------------------------------------

## Conclusion

This project demonstrates practical AI-native quality engineering by
combining structured prompt engineering, real-time LLM integration,
automated failure triage, and clean architecture separation.

The focus was not just automation --- but intelligent automation.
