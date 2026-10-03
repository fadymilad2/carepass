const apiKey = process.env.GEMINI_API_KEY;
if (!apiKey) throw new Error('Set GEMINI_API_KEY before running this diagnostic.');

fetch(`https://generativelanguage.googleapis.com/v1beta/models?key=${apiKey}`)
  .then(response => response.json())
  .then(data => {
    console.log("✅ الموديلات المتاحة للمفتاح بتاعك:");
    const models = data.models.map(m => m.name.replace('models/', ''));
    console.log(models);
  })
  .catch(err => console.error("❌ إيرور:", err));