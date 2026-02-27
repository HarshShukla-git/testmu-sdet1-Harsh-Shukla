package llm;

import org.openqa.selenium.WebDriver;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.time.LocalDateTime;

public class FailureExplainer {

    public static void explainFailure(String testName,
                                      Throwable throwable,
                                      WebDriver driver) {

        try {

            String currentUrl = driver != null ? driver.getCurrentUrl() : "Unavailable";
            String pageSource = driver != null ? driver.getPageSource() : "Unavailable";

            if (pageSource.length() > 3000) {
                pageSource = pageSource.substring(0, 3000);
            }

            String prompt = "You are a Senior QA Engineer.\n\n"
                    + "A Selenium test has failed.\n\n"
                    + "Test Name: " + testName + "\n"
                    + "Error: " + throwable.getMessage() + "\n"
                    + "URL: " + currentUrl + "\n\n"
                    + "Page Snapshot:\n" + pageSource + "\n\n"
                    + "Provide:\n"
                    + "1. Root cause\n"
                    + "2. Likely category (Bug / Locator / Timing / Assertion / Env)\n"
                    + "3. Suggested fix\n"
                    + "4. Confidence level.";

            String aiResponse = LLMClient.callLLM(prompt);

            saveReport(testName, throwable, currentUrl, aiResponse);

            System.out.println("✅ AI Failure Explanation Generated.");

        } catch (Exception e) {
            System.out.println("❌ AI explanation failed: " + e.getMessage());
        }
    }

    private static void saveReport(String testName,
                                   Throwable throwable,
                                   String currentUrl,
                                   String aiResponse) throws IOException {

        File folder = new File("reports");
        if (!folder.exists()) folder.mkdir();

        FileWriter writer = new FileWriter("reports/ai-failure-report.txt", true);

        writer.write("\n\n=================================================\n");
        writer.write("Timestamp: " + LocalDateTime.now() + "\n");
        writer.write("Test: " + testName + "\n");
        writer.write("URL: " + currentUrl + "\n");
        writer.write("Error: " + throwable.getMessage() + "\n\n");
        writer.write("--------- AI ANALYSIS ---------\n");
        writer.write(aiResponse + "\n");
        writer.write("=================================================\n");

        writer.close();
    }
}
