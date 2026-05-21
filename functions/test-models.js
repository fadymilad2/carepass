const apiKey = "AIzaSyBsgXc3TLxzOmMNFLoobCnzQNpqB2OtqnU";

fetch(`https://generativelanguage.googleapis.com/v1beta/models?key=${apiKey}`)
  .then(response => response.json())
  .then(data => {
    console.log("✅ الموديلات المتاحة للمفتاح بتاعك:");
    const models = data.models.map(m => m.name.replace('models/', ''));
    console.log(models);
  })
  .catch(err => console.error("❌ إيرور:", err));