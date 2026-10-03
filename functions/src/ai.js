const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const { defineSecret } = require("firebase-functions/params");

const geminiApiKey = defineSecret("GEMINI_API_KEY");

// ── AI Health Assistant ────────────────────────────────────────────────
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
    const uid = auth?.uid;

    if (!uid) {
      throw new HttpsError(
        "unauthenticated",
        "Session expired. Please login again."
      );
    }

    if (typeof data?.message !== 'string' || !data.message.trim() || data.message.length > 30000) {
      throw new HttpsError('invalid-argument', 'A message of up to 30000 characters is required.');
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
        maxOutputTokens: 512,
      },
    });

    const prompt = `
You are CarePass AI Health Assistant.
Be CONCISE. Maximum 3-4 sentences per response. No long explanations.

Rules:
- Respond in the SAME language as the patient
- For emergencies (chest pain, difficulty breathing) → say "URGENT: See a doctor immediately"
- Always end with: "This is not medical advice. Please consult a doctor."
- Suggest ONE medical specialty only
- Suggest maximum TWO tests

After your short response, output ONLY this JSON on a new line (no markdown, no backticks):
{"specialty":"General Practitioner","tests":["Blood test"],"urgency":"low","conditions":["Possible cold"]}

Urgency values: "low", "medium", "high", "emergency"

Patient message:
${data.message}
`;

    try {
      console.log("Calling Gemini for uid:", uid);
      const result = await model.generateContent(prompt);
      const text = result.response.text();
      console.log("Response length:", text.length);
      return { content: text };
    } catch (error) {
      console.error("Gemini Error:", error.message);
      if (
        error.message?.includes("not found") ||
        error.message?.includes("404")
      ) {
        throw new HttpsError(
          "not-found",
          `Model not available: ${error.message}`
        );
      }
      throw new HttpsError("internal", `API Error: ${error.message}`);
    }
  }
);

