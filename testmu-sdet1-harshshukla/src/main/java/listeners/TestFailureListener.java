/*
 * Chosen Option A — Failure Explainer
 *
 * Reason:
 * - Provides real-time root cause analysis
 * - Helps reduce debugging time
 * - Directly integrates LLM into test lifecycle
 * - Scales better than post-run log classification
 *
 * This approach enables AI-assisted triage immediately when failures occur.
 */


package listeners;

import llm.FailureExplainer;
import org.openqa.selenium.WebDriver;
import org.testng.ITestListener;
import org.testng.ITestResult;

import base.BaseTest;

public class TestFailureListener implements ITestListener {

    @Override
    public void onTestFailure(ITestResult result) {

        Object currentClass = result.getInstance();
        WebDriver driver = ((BaseTest) currentClass).getDriver();
        
        FailureExplainer.explainFailure(
                result.getName(),
                result.getThrowable(),
                driver
        );
    }
}