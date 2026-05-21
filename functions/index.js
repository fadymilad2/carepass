const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const { defineSecret } = require("firebase-functions/params");

const geminiApiKey = defineSecret("GEMINI_API_KEY");
exports.aiHealthAssistant = onCall(
  {
    enforceAppCheck: false,
    cors: true,
    secrets: [geminiApiKey],
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  async (request) => {
    const data = request.data;
    const auth = request.auth;
    const uid = (auth && auth.uid) || (data && data.userId);

    if (!uid) {
      throw new HttpsError(
        "unauthenticated",
        "Session expired. Please login again."
      );
    }

    const apiKey = geminiApiKey.value();
    if (!apiKey) {
      throw new HttpsError("internal", "API Key is missing");
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
      model: "gemini-flash-latest",
      generationConfig: {
        temperature: 0.3,
        maxOutputTokens: 1024,
      },
    });

    const prompt = `
You are CarePass AI Health Assistant — a helpful, empathetic medical guidance assistant.

Your job:
1. Listen carefully to the user's symptoms
2. Ask clarifying questions if needed (age, duration, severity)
3. Suggest the most appropriate medical specialty
4. Recommend relevant tests
5. Assess urgency level

RULES:
- Always remind users this is preliminary guidance only
- For emergencies (chest pain, difficulty breathing) → urgency: "emergency"
- Be compassionate and clear
- Respond in the SAME language the patient uses

After your conversational response, ALWAYS output this JSON block:
{
  "specialty": "General Practitioner",
  "tests": ["Blood test"],
  "conditions": ["Common cold"],
  "urgency": "low",
  "disclaimer": "Preliminary assessment only. Please consult a licensed physician."
}

Chat History and Current Input:
${data.message}
`;

    try {
      console.log("Calling Gemini for user:", uid);
      const result = await model.generateContent(prompt);
      const text = result.response.text();
      console.log("Response length:", text.length);
      return { content: text };
    } catch (error) {
      console.error("Gemini Error:", error.message);

      if (error.message?.includes("not found") ||
        error.message?.includes("404")) {
        throw new HttpsError(
          "not-found",
          `Model not available: ${error.message}`
        );
      }

      throw new HttpsError("internal", `API Error: ${error.message}`);
    }
  }
);