# AI Usage Log

------------------------------------------------------------------------

## AI Tools Used

-   ChatGPT (OpenAI GPT-4o-mini via API)
- opus 4.6

------------------------------------------------------------------------

# Task 2 --- Test Generation

### Used For:

-   Generating structured regression test cases
-   Refining prompt clarity and structure
-   Expanding boundary and security coverage
-   Formatting output into Gherkin feature files

### Output Produced:

-   Login regression suite
-   Dashboard regression suite
-   REST API regression suite
-   Prompt refinement iterations

------------------------------------------------------------------------

# Task 3 --- LLM Framework Integration

### Used For:

-   Designing structured failure analysis prompt
-   Generating root cause explanations
-   Classifying failure category
-   Suggesting code-level fixes
-   Returning confidence score

### Integration Method:

-   Real OpenAI API call via OkHttp
-   Triggered inside TestNG ITestListener
-   Failure context (error + URL + DOM snapshot) sent dynamically
-   Output saved automatically to reports/ai-failure-report.txt

------------------------------------------------------------------------

## Important Note

The LLM call is NOT mocked.

The system sends real-time failure context to OpenAI and processes the
returned response inside the automation framework.
