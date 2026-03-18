import OpenAI from 'openai';
import Document from '../models/Document.js';

// Initialize OpenAI client pointing to GitHub Models
const client = new OpenAI({
  baseURL: process.env.AI_BASE_URL || 'https://models.github.ai/inference',
  apiKey: process.env.GITHUB_TOKEN || 'dummy_key',
});

// @desc    Query user documents via AI
// @route   POST /api/ai/query
// @access  Private (User)
export const queryAI = async (req, res) => {
  try {
    const { question } = req.body;

    // Fetch user's documents
    const documents = await Document.find({ userId: req.user._id });

    if (documents.length === 0) {
      return res.json({ reply: "You don't have any uploaded documents yet." });
    }

    // Prepare context
    const docsContext = documents.map(doc => {
      let metaStr = doc.metadata ? JSON.stringify(Object.fromEntries(doc.metadata)) : '{}';
      return `- Title: ${doc.title}, Category: ${doc.category}, Expiry: ${doc.expiryDate || 'N/A'}, Metadata: ${metaStr}`;
    }).join('\n');

    const systemPrompt = `You are a helpful and secure document assistant for TrustVault. 
Here is a list of the user's current documents and their metadata:
${docsContext}

Answer the user's question accurately based ONLY on the provided document information. If the answer is not in the context, say "I cannot find that information in your current documents." Do not invent information.`;

    const modelName = process.env.AI_MODEL || 'openai/gpt-4o-mini';

    const response = await client.chat.completions.create({
      model: modelName,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: question },
      ],
      temperature: 0.1, // Keep it deterministic
    });

    res.json({ reply: response.choices[0].message.content });
  } catch (error) {
    console.error('AI Query Error:', error);
    res.status(500).json({ message: 'Failed to process AI query', details: error.message });
  }
};
