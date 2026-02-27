package llm;

import okhttp3.*;
import org.json.JSONObject;
import org.json.JSONArray;

import java.io.IOException;
import java.util.concurrent.TimeUnit;

public class LLMClient {

    private static final String API_URL = "https://api.openai.com/v1/chat/completions";
    private static final String API_KEY = System.getenv("OPENAI_API_KEY");

    public static String callLLM(String prompt) throws IOException {

        if (API_KEY == null || API_KEY.isEmpty()) {
            return "ERROR: OPENAI_API_KEY environment variable not set.";
        }

        // ✅ Increased timeouts to avoid timeout errors
        OkHttpClient client = new OkHttpClient.Builder()
                .connectTimeout(30, TimeUnit.SECONDS)
                .readTimeout(60, TimeUnit.SECONDS)
                .writeTimeout(30, TimeUnit.SECONDS)
                .build();

        // Build JSON request
        JSONObject message = new JSONObject();
        message.put("role", "user");
        message.put("content", prompt);

        JSONArray messages = new JSONArray();
        messages.put(message);

        JSONObject requestBodyJson = new JSONObject();
        requestBodyJson.put("model", "gpt-4o-mini");
        requestBodyJson.put("messages", messages);
        requestBodyJson.put("temperature", 0.2);

        RequestBody body = RequestBody.create(
                requestBodyJson.toString(),
                MediaType.parse("application/json")
        );

        Request request = new Request.Builder()
                .url(API_URL)
                .addHeader("Authorization", "Bearer " + API_KEY)
                .addHeader("Content-Type", "application/json")
                .post(body)
                .build();

        try (Response response = client.newCall(request).execute()) {

            if (!response.isSuccessful()) {
                return "LLM call failed: HTTP "
                        + response.code()
                        + " - "
                        + response.message();
            }

            String responseBody = response.body().string();

            JSONObject jsonResponse = new JSONObject(responseBody);

            return jsonResponse
                    .getJSONArray("choices")
                    .getJSONObject(0)
                    .getJSONObject("message")
                    .getString("content");

        } catch (Exception e) {
            return "LLM call exception: " + e.getMessage();
        }
    }
}